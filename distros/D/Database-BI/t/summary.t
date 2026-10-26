use strict;
use warnings;

# ---------------------------------------------------------------------------
# t/summary.t -- Tests for Phase 5.3 narrative summaries.
#
# All tests are hermetic: the LLM path is exercised by mocking
# LWP::UserAgent::request so no real API call is made.
# ---------------------------------------------------------------------------

use Test::Most;
use Test::Mojo;
use File::Spec ();
use File::Temp qw(tempdir);
use Mojo::Util qw(url_escape);
use Readonly;

my $t = Test::Mojo->new('Database::BI');

# The model store (.bi/) is shared state in the checkout: give this file its
# own directory, so a parallel run cannot create, read or write it underneath.
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

Readonly my $FIXTURE => File::Spec->rel2abs('data/insights_fixture.csv');
plan skip_all => 'data/insights_fixture.csv not found' unless -f $FIXTURE;

use_ok('Database::BI::Summary');
use_ok('Database::BI::Insights');

# ---------------------------------------------------------------------------
# Helper: build a small insight list from the fixture
# ---------------------------------------------------------------------------
my @FIXTURE_ROWS;
{
    open my $fh, '<', $FIXTURE or die "Cannot open $FIXTURE: $!";
    my $header = <$fh>;
    chomp $header;
    my @cols = split /,/, $header;
    while (my $line = <$fh>) {
        chomp $line;
        my @vals = split /,/, $line;
        my %row;
        @row{@cols} = @vals;
        push @FIXTURE_ROWS, \%row;
    }
    close $fh;
}

my $FIXTURE_INSIGHTS = Database::BI::Insights::compute(
    records  => \@FIXTURE_ROWS,
    columns  => [qw(region sale_date amount)],
    spec_key => 'table:insights_fixture',
);
ok(scalar(@$FIXTURE_INSIGHTS) > 0, 'fixture produces at least one insight');

# ---------------------------------------------------------------------------
# Section 1: Template path -- generate() without AI
# ---------------------------------------------------------------------------

{
    my $result = Database::BI::Summary::generate(
        insights  => $FIXTURE_INSIGHTS,
        spec_key  => 'table:insights_fixture',
        label     => 'insights_fixture',
        row_count => scalar @FIXTURE_ROWS,
    );

    ok(ref($result) eq 'HASH',        'generate() returns a hashref');
    ok(defined $result->{text},       'result has text key');
    ok(length($result->{text}) > 10,  'text is non-trivial');
    is($result->{source}, 'template', 'source is "template"');
    is($result->{cached}, 0,          'first call: cached=0');

    # Text should mention the label and a row count.
    like($result->{text}, qr/insights_fixture/, 'text mentions dataset label');
    like($result->{text}, qr/\d+ rows? analysed/i, 'text mentions row count');
}

# ---------------------------------------------------------------------------
# Section 2: Cache hit -- second call with identical insights returns cached=1
# ---------------------------------------------------------------------------

{
    my $first = Database::BI::Summary::generate(
        insights  => $FIXTURE_INSIGHTS,
        label     => 'cache_test_label_xyz',
        row_count => 7,
    );
    is($first->{cached}, 0, 'first call for unique label: cached=0');

    my $second = Database::BI::Summary::generate(
        insights  => $FIXTURE_INSIGHTS,
        label     => 'cache_test_label_xyz',
        row_count => 7,
    );
    is($second->{cached}, 1,                 'second call with same insights: cached=1');
    is($second->{text},   $first->{text},    'cached text is identical');
    is($second->{source}, $first->{source},  'cached source is identical');
}

# ---------------------------------------------------------------------------
# Section 3: Cache miss -- different insights produce a fresh result
# ---------------------------------------------------------------------------

{
    my $tiny_insights = [
        { kind => 'outlier', headline => 'unique_xyz val 999 in grp A is high',
          detail => 'Q3=100, fence=200, value=999', method => 'iqr_fence' },
    ];
    my $a = Database::BI::Summary::generate(
        insights  => $tiny_insights,
        label     => 'tiny',
        row_count => 5,
    );
    is($a->{cached}, 0, 'different insights: not a cache hit');
}

# ---------------------------------------------------------------------------
# Section 4: use_ai=1 without api_key falls back to template
# ---------------------------------------------------------------------------

{
    my $result = Database::BI::Summary::generate(
        insights  => $FIXTURE_INSIGHTS,
        label     => 'ai_fallback_test',
        row_count => 39,
        use_ai    => 1,
        ai_config => { provider => 'anthropic', api_key => '', model => 'claude-haiku-5-5' },
    );
    is($result->{source}, 'template', 'empty api_key falls back to template path');
    like($result->{text}, qr/ai_fallback_test/, 'fallback text mentions label');
}

# ---------------------------------------------------------------------------
# Section 5: use_ai=1 with mocked LWP::UserAgent::request -> source='llm'
# ---------------------------------------------------------------------------

SKIP: {
    eval { require LWP::UserAgent; require HTTP::Response; require HTTP::Headers }
        or skip 'LWP not available', 5;

    my $mocked_text = 'Insights summary from mocked provider.';

    my @call_args;
    local *LWP::UserAgent::request = sub {
        my ($self_ua, $req) = @_;
        push @call_args, { url => $req->uri->as_string, body => $req->content };
        require HTTP::Response;
        require HTTP::Headers;
        my $json_body = '{"content":[{"type":"text","text":"' . $mocked_text . '"}]}';
        return HTTP::Response->new(
            200, 'OK',
            HTTP::Headers->new('Content-Type' => 'application/json'),
            $json_body,
        );
    };

    my $result = Database::BI::Summary::generate(
        insights  => [
            { kind => 'outlier', headline => 'llm test outlier', detail => 'detail', method => 'iqr_fence' },
        ],
        label     => 'llm_test_dataset',
        row_count => 20,
        use_ai    => 1,
        ai_config => { provider => 'anthropic', api_key => 'sk-test-key', model => 'claude-haiku-5-5' },
    );

    is($result->{source}, 'llm',     'AI path returns source=llm');
    is($result->{text},   $mocked_text, 'AI path returns mocked response text');
    is($result->{cached}, 0,            'AI path: cached=0 on first call');
    ok(scalar @call_args == 1,          'LWP::UserAgent::request called exactly once');
    like($call_args[0]{url}, qr{anthropic\.com/v1/messages},
        'request sent to Anthropic Messages API endpoint');
}

# ---------------------------------------------------------------------------
# Section 6: LLM failure falls back to template_fallback
# ---------------------------------------------------------------------------

SKIP: {
    eval { require LWP::UserAgent; require HTTP::Response; require HTTP::Headers }
        or skip 'LWP not available', 3;

    local *LWP::UserAgent::request = sub {
        require HTTP::Response;
        require HTTP::Headers;
        return HTTP::Response->new(
            500, 'Internal Server Error',
            HTTP::Headers->new('Content-Type' => 'application/json'),
            '{"error":{"type":"api_error","message":"Server error"}}',
        );
    };

    my $result = Database::BI::Summary::generate(
        insights  => [
            { kind => 'period_delta', headline => 'fallback test delta', detail => 'up 10%', method => 'pop_delta' },
        ],
        label     => 'fallback_test',
        row_count => 5,
        use_ai    => 1,
        ai_config => { provider => 'anthropic', api_key => 'sk-test-key', model => 'claude-haiku-5-5' },
    );

    is($result->{source}, 'template_fallback', 'LLM error falls back to template_fallback');
    ok(defined $result->{text} && length $result->{text}, 'fallback still produces text');
    like($result->{text}, qr/fallback_test/, 'fallback text mentions label');
}

# ---------------------------------------------------------------------------
# Section 7: HTTP endpoint tests (POST /api/summary)
# ---------------------------------------------------------------------------

{
    my $enc = url_escape($FIXTURE);

    # Missing l= returns 400.
    $t->post_ok('/api/summary', form => {})->status_is(400)
      ->json_like('/error', qr/./, 'missing l= gives error key in JSON');

    # Valid request returns 200 with text, source, cached.
    $t->post_ok('/api/summary', form => { l => "path:$FIXTURE" })
      ->status_is(200)
      ->json_has('/text', 'response has text key')
      ->json_has('/source', 'response has source key')
      ->json_has('/cached', 'response has cached key');

    my $text = $t->tx->res->json->{text};
    ok(defined $text && length $text > 5, 'text field is non-trivial');

    my $source = $t->tx->res->json->{source};
    like($source, qr/\Atemplate/, 'source starts with "template" when AI not configured');

    # Filter forwarding: the endpoint accepts f= and returns 200.
    $t->post_ok('/api/summary', form => {
        l => "path:$FIXTURE",
        f => 'region:eq:North',
    })->status_is(200)
      ->json_has('/text', 'filtered request returns text key');

    # Unknown table returns 404.
    $t->post_ok('/api/summary', form => { l => 'table:does_not_exist_xyz' })
      ->status_is(404)
      ->json_like('/error', qr/./, '404 has error key');

    # ai=1 without configured api_key falls back to template (no 5xx).
    $t->post_ok('/api/summary', form => { l => "path:$FIXTURE", ai => 1 })
      ->status_is(200)
      ->json_has('/text', 'ai=1 without key still returns text')
      ->json_like('/source', qr/\Atemplate/, 'ai=1 without key uses template path');
}

# ---------------------------------------------------------------------------
# Section 8: Template sentence coverage
# ---------------------------------------------------------------------------

{
    # Single outlier -> "An unusual value was detected".
    my $single_out = [
        { kind => 'outlier', headline => 'amount 999 in West is high',
          detail => 'fence=325', method => 'iqr_fence' },
    ];
    my $r = Database::BI::Summary::generate(
        insights  => $single_out,
        label     => 'testset',
        row_count => 10,
    );
    like($r->{text}, qr/unusual value/i, 'single outlier sentence present');

    # Multiple outliers -> "N outliers detected".
    my $multi_out = [
        { kind => 'outlier', headline => 'amount 999 in West is high',
          detail => 'fence=325', method => 'iqr_fence' },
        { kind => 'outlier', headline => 'amount 888 in East is high',
          detail => 'fence=325', method => 'iqr_fence' },
    ];
    my $r2 = Database::BI::Summary::generate(
        insights  => $multi_out,
        label     => 'testset2',
        row_count => 10,
    );
    like($r2->{text}, qr/2 outliers detected/i, 'multiple outliers sentence uses count');

    # period_delta -> mentions headline and detail.
    my $delta = [
        { kind => 'period_delta', headline => 'amount up 15%', detail => '2025-12 vs 2026-01',
          method => 'pop_delta' },
    ];
    my $r3 = Database::BI::Summary::generate(
        insights  => $delta,
        label     => 'dset3',
        row_count => 5,
    );
    like($r3->{text}, qr/up 15%/, 'period_delta text includes headline');

    # seasonality -> "repeating seasonal pattern".
    my $season = [
        { kind => 'seasonality', headline => 'amount has seasonal trend (r=0.78)',
          detail => '12 periods', method => 'autocorr' },
    ];
    my $r4 = Database::BI::Summary::generate(
        insights  => $season,
        label     => 'dset4',
        row_count => 12,
    );
    like($r4->{text}, qr/seasonal/i, 'seasonality text mentions seasonal');

    # No insights -> "No significant patterns".
    my $r5 = Database::BI::Summary::generate(
        insights  => [],
        label     => 'empty',
        row_count => 0,
    );
    like($r5->{text}, qr/No significant patterns/i, 'empty insights produces no-patterns sentence');
}

# ---------------------------------------------------------------------------
# Section 9: Insights page now contains Summarize button
# ---------------------------------------------------------------------------

{
    my $enc = url_escape($FIXTURE);
    $t->get_ok("/insights?l=path:$enc")
      ->status_is(200)
      ->content_like(qr/btn-summarize/, 'insights page has btn-summarize element')
      ->content_like(qr/summary-box/,   'insights page has summary-box element')
      ->content_like(qr/\/api\/summary/, 'insights page references /api/summary endpoint');
}

done_testing;
