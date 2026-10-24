use strict;
use warnings;

# ---------------------------------------------------------------------------
# t/insights.t -- Tests for Phase 5.2 automatic insights.
#
# All tests are hermetic: no live LLM, no network calls.
# The fixture data/insights_fixture.csv has:
#   - A known outlier: West region 2025-07-01 amount=999 (IQR fence)
#   - Period-over-period changes between 2025-12 and 2026-01
#   - 13+ month-periods for seasonality detection
# ---------------------------------------------------------------------------

use Test::Most;
use Test::Mojo;
use File::Spec ();
use Mojo::Util qw(url_escape);
use Readonly;

# ---------------------------------------------------------------------------
# Bootstrap
# ---------------------------------------------------------------------------
my $t = Test::Mojo->new('Database::BI');

Readonly my $FIXTURE => File::Spec->rel2abs('data/insights_fixture.csv');
plan skip_all => 'data/insights_fixture.csv not found' unless -f $FIXTURE;

use_ok('Database::BI::Insights');

# ---------------------------------------------------------------------------
# Section 1: Unit tests for Database::BI::Insights::compute()
# ---------------------------------------------------------------------------

{
    # Build a minimal in-memory fixture replicating the CSV structure.
    my @rows;
    open my $fh, '<', $FIXTURE or die "Cannot open $FIXTURE: $!";
    my $header = <$fh>;
    chomp $header;
    my @cols = split /,/, $header;
    while (my $line = <$fh>) {
        chomp $line;
        my @vals = split /,/, $line;
        my %row;
        @row{@cols} = @vals;
        push @rows, \%row;
    }
    close $fh;

    my $insights = Database::BI::Insights::compute(
        records  => \@rows,
        columns  => \@cols,
        spec_key => 'path:' . $FIXTURE,
        base_url => '/insights?l=path:' . $FIXTURE,
    );

    ok(ref($insights) eq 'ARRAY', 'compute() returns an arrayref');
    ok(scalar(@$insights) > 0,    'at least one insight detected');

    # Every insight must have the required keys.
    for my $ins (@$insights) {
        ok(defined $ins->{kind},     "insight has kind ($ins->{kind})");
        ok(defined $ins->{headline}, "insight has headline");
        ok(defined $ins->{detail},   "insight has detail");
        ok(defined $ins->{view_url}, "insight has view_url");
        ok(defined $ins->{method},   "insight has method");
        ok(length($ins->{view_url}), 'view_url is non-empty');
        like($ins->{view_url}, qr{\A/}, 'view_url is root-relative');
    }

    # West 999 spike must be detected as an outlier.
    my @outliers = grep { $_->{kind} eq 'outlier' } @$insights;
    ok(scalar(@outliers) >= 1, 'at least one outlier detected');
    my ($spike_insight) = grep { $_->{headline} =~ /999/ } @outliers;
    ok(defined $spike_insight, 'outlier insight mentions the 999 spike value');

    # period_delta insight must exist (2025-12 vs 2026-01).
    my @pop = grep { $_->{kind} eq 'period_delta' } @$insights;
    ok(scalar(@pop) >= 1, 'at least one period_delta insight detected');
    like($pop[0]->{detail}, qr/2025-12/, 'period_delta mentions the prior period');
    like($pop[0]->{detail}, qr/2026-01/, 'period_delta mentions the current period');

    # top_mover insight must exist (South had bigger absolute jump than North or West).
    my @movers = grep { $_->{kind} eq 'top_mover' } @$insights;
    ok(scalar(@movers) >= 1, 'at least one top_mover insight detected');

    # Every insight view_url must not contain an unescaped space.
    for my $ins (@$insights) {
        unlike($ins->{view_url}, qr/ /, "view_url contains no raw spaces: $ins->{kind}");
    }
}

# ---------------------------------------------------------------------------
# Section 2: Non-ISO date columns must not be treated as numeric
# ---------------------------------------------------------------------------

{
    # US bank export: Post Date in M/D/YYYY format.  Without the fix, _to_num
    # strips the slashes and turns 12/22/2025 into 12222025 -- a large integer
    # that then triggers the IQR outlier detector.
    my @rows = map {
        { 'Post Date' => "12/$_/2025", Description => 'Acme', Amount => 100 + $_ }
    } 1..10;
    my $insights = Database::BI::Insights::compute(
        records  => \@rows,
        columns  => ['Post Date', 'Description', 'Amount'],
        spec_key => 'table:bank',
    );
    my @date_outliers = grep {
        $_->{kind} eq 'outlier' && $_->{headline} =~ /Post Date/
    } @$insights;
    is(scalar(@date_outliers), 0,
        'US slash-date column (M/D/YYYY) is not reported as a numeric outlier');
}

{
    # EU bank export: D/M/YYYY format -- same guard applies.
    my @rows = map {
        { 'Trans Date' => "$_/12/2025", Merchant => 'Shop', Amount => 50 + $_ }
    } 1..10;
    my $insights = Database::BI::Insights::compute(
        records  => \@rows,
        columns  => ['Trans Date', 'Merchant', 'Amount'],
        spec_key => 'table:eubank',
    );
    my @date_outliers = grep {
        $_->{kind} eq 'outlier' && $_->{headline} =~ /Trans Date/
    } @$insights;
    is(scalar(@date_outliers), 0,
        'EU slash-date column (D/M/YYYY) is not reported as a numeric outlier');
}

{
    # DD-Mon-YYYY format (common in Oracle / older Excel exports).
    my @rows = map {
        { Date => sprintf('%02d-Oct-2026', $_), Val => 100 + $_ }
    } 1..10;
    my $insights = Database::BI::Insights::compute(
        records  => \@rows,
        columns  => ['Date', 'Val'],
        spec_key => 'table:oracle',
    );
    my @date_outliers = grep {
        $_->{kind} eq 'outlier' && $_->{headline} =~ /\bDate\b/
    } @$insights;
    is(scalar(@date_outliers), 0,
        'DD-Mon-YYYY date column is not reported as a numeric outlier');
}

# ---------------------------------------------------------------------------
# Section 3: Insufficient data path
# ---------------------------------------------------------------------------

{
    # A dataset with one numeric column and only 1 row: nothing to report.
    my $insights = Database::BI::Insights::compute(
        records  => [{ amount => 100 }],
        columns  => ['amount'],
        spec_key => 'table:tiny',
    );
    ok(ref($insights) eq 'ARRAY', 'compute() returns arrayref for tiny input');
    is(scalar(@$insights), 0, 'no insights on a single-row dataset');
}

{
    # A dataset with only non-numeric columns: no outliers/movers.
    my $insights = Database::BI::Insights::compute(
        records  => [map { { name => "row$_", tag => 'x' } } 1..10],
        columns  => ['name', 'tag'],
        spec_key => 'table:nonnumeric',
    );
    is(scalar(@$insights), 0, 'no insights when no numeric columns');
}

{
    # Fewer than MIN_PERIODS_SEASON (8) periods: no seasonality insight.
    my @rows = map {
        { sale_date => sprintf('2025-%02d-01', $_), amount => 100 + $_ }
    } 1..5;
    my $insights = Database::BI::Insights::compute(
        records  => \@rows,
        columns  => [qw(sale_date amount)],
        spec_key => 'table:few_periods',
    );
    my @season = grep { $_->{kind} eq 'seasonality' } @$insights;
    is(scalar(@season), 0, 'no seasonality insight with fewer than 8 periods');
}

# ---------------------------------------------------------------------------
# Section 4: HTTP endpoint tests (GET /insights)
# ---------------------------------------------------------------------------

{
    my $enc = url_escape("path:$FIXTURE");

    # Basic smoke: 200, page renders, no crash.
    $t->get_ok("/insights?l=path:${\url_escape($FIXTURE)}")
      ->status_is(200)
      ->content_like(qr/Automatic insights/i, 'page title present')
      ->content_like(qr/insight-card/, 'at least one insight card rendered');

    # Outlier card present in HTML.
    $t->get_ok("/insights?l=path:${\url_escape($FIXTURE)}")
      ->content_like(qr/outlier/i, 'outlier kind shown in HTML');

    # Every view_url in the page must be a root-relative path.
    $t->get_ok("/insights?l=path:${\url_escape($FIXTURE)}")
      ->content_unlike(qr/view_url.*javascript:/i, 'no javascript: in any insight URL');

    # Missing l= returns 400.
    $t->get_ok('/insights')
      ->status_is(400);

    # Unknown table returns 404.
    $t->get_ok('/insights?l=table:does_not_exist_xyz')
      ->status_is(404);

    # f= filter is forwarded: filtering to North reduces data but still returns 200.
    $t->get_ok("/insights?l=path:${\url_escape($FIXTURE)}&f=region:eq:North")
      ->status_is(200);
}

# ---------------------------------------------------------------------------
# Section 5: method_note() returns non-empty strings for all known keys
# ---------------------------------------------------------------------------

{
    for my $key (qw(iqr_fence pop_delta top_mover autocorr)) {
        my $note = Database::BI::Insights::method_note($key);
        ok(defined $note && length $note, "method_note('$key') returns a string");
    }
}

# ---------------------------------------------------------------------------
# Section 6: drill_url present and well-formed for outlier/period_delta/top_mover
# ---------------------------------------------------------------------------

{
    my @rows;
    open my $fh, '<', $FIXTURE or die "Cannot open $FIXTURE: $!";
    my $header = <$fh>;
    chomp $header;
    my @cols = split /,/, $header;
    while (my $line = <$fh>) {
        chomp $line;
        my @vals = split /,/, $line;
        my %row;
        @row{@cols} = @vals;
        push @rows, \%row;
    }
    close $fh;

    # Use a table: spec so drill URLs are /view/... (easier to assert).
    my $insights = Database::BI::Insights::compute(
        records  => \@rows,
        columns  => \@cols,
        spec_key => 'table:insights_fixture',
        base_url => '/insights?l=table:insights_fixture',
    );

    # Outlier insights with a categorical column must carry a drill_url.
    my @outliers = grep { $_->{kind} eq 'outlier' } @$insights;
    ok(scalar(@outliers) >= 1, 'section 6: outlier insights present');
    for my $o (@outliers) {
        ok(defined $o->{drill_url}, "outlier insight has drill_url");
        like($o->{drill_url}, qr{\A/view/insights_fixture\?}, 'outlier drill_url starts with /view/...');
        like($o->{drill_url}, qr/f=region%3Aeq%3A|f=region:eq:/,
            'outlier drill_url contains category filter');
        like($o->{drill_url}, qr/hl_col=/, 'outlier drill_url has hl_col param');
        like($o->{drill_url}, qr/hl_op=(?:gt|lt)/, 'outlier drill_url has hl_op gt or lt');
        like($o->{drill_url}, qr/hl_val=/, 'outlier drill_url has hl_val param');
        like($o->{drill_url}, qr/back2=/, 'outlier drill_url has back2 breadcrumb');
        unlike($o->{drill_url}, qr/ /, 'outlier drill_url has no raw spaces');
    }

    # period_delta insights must carry a drill_url.
    my @pop = grep { $_->{kind} eq 'period_delta' } @$insights;
    ok(scalar(@pop) >= 1, 'section 6: period_delta insights present');
    for my $p (@pop) {
        ok(defined $p->{drill_url}, "period_delta insight has drill_url");
        like($p->{drill_url}, qr{\A/view/insights_fixture}, 'period_delta drill_url is /view/...');
        like($p->{drill_url}, qr/f=sale_date/, 'period_delta drill_url contains date filter');
        like($p->{drill_url}, qr/back2=/, 'period_delta drill_url has back2 breadcrumb');
        unlike($p->{drill_url}, qr/ /, 'period_delta drill_url has no raw spaces');
    }

    # top_mover insights must carry a drill_url.
    my @movers = grep { $_->{kind} eq 'top_mover' } @$insights;
    ok(scalar(@movers) >= 1, 'section 6: top_mover insights present');
    for my $m (@movers) {
        ok(defined $m->{drill_url}, "top_mover insight has drill_url");
        like($m->{drill_url}, qr{\A/view/insights_fixture}, 'top_mover drill_url is /view/...');
        like($m->{drill_url}, qr/f=sale_date/, 'top_mover drill_url contains date filter');
        like($m->{drill_url}, qr/f=region/, 'top_mover drill_url contains category filter');
        like($m->{drill_url}, qr/back2=/, 'top_mover drill_url has back2 breadcrumb');
        unlike($m->{drill_url}, qr/ /, 'top_mover drill_url has no raw spaces');
    }

    # seasonality insights should NOT have a drill_url (pattern spans many rows).
    my @season = grep { $_->{kind} eq 'seasonality' } @$insights;
    for my $s (@season) {
        ok(!defined $s->{drill_url}, 'seasonality insight has no drill_url');
    }
}

{
    # path: spec generates /open?path=... drill URLs.
    my @rows;
    open my $fh, '<', $FIXTURE or die "Cannot open $FIXTURE: $!";
    my $header = <$fh>;
    chomp $header;
    my @cols = split /,/, $header;
    while (my $line = <$fh>) {
        chomp $line;
        my @vals = split /,/, $line;
        my %row;
        @row{@cols} = @vals;
        push @rows, \%row;
    }
    close $fh;

    my $insights = Database::BI::Insights::compute(
        records  => \@rows,
        columns  => \@cols,
        spec_key => "path:$FIXTURE",
        base_url => "/insights?l=path:$FIXTURE",
    );

    my @has_drill = grep { defined $_->{drill_url} } @$insights;
    ok(scalar(@has_drill) >= 1, 'path: spec produces at least one insight with drill_url');
    for my $ins (@has_drill) {
        like($ins->{drill_url}, qr{\A/open\?path=}, 'path: drill_url starts with /open?path=');
        unlike($ins->{drill_url}, qr/ /, 'path: drill_url has no raw spaces');
    }
}

{
    # HTTP: "See rows" link text appears in the insights page.
    my $enc = url_escape($FIXTURE);
    $t->get_ok("/insights?l=path:$enc")
      ->status_is(200)
      ->content_like(qr/See rows/, 'insights page contains "See rows" drill link text')
      ->content_like(qr/insight-drill-link/, 'insights page contains drill-link CSS class');

    # HTTP: drill_url params (hl_col/hl_op/hl_val) on /open must not cause a 500.
    $t->get_ok("/open?path=${enc}&f=region:eq:West&hl_col=amount&hl_op=gt&hl_val=500")
      ->status_is(200, '/open with hl params returns 200 (highlight is client-side only)');

    # HTTP: hl-row CSS class must appear in the dashboard layout when loaded.
    $t->get_ok("/open?path=${enc}")
      ->status_is(200)
      ->content_like(qr/hl-row/, 'dashboard layout contains hl-row CSS class');
}

done_testing;
