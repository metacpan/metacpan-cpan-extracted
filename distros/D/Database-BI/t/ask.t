use strict;
use warnings;

# ---------------------------------------------------------------------------
# t/ask.t -- Tests for Phase 5.1 natural-language-to-spec (Ask).
#
# All tests are hermetic: the LLM path is exercised by mocking
# LWP::UserAgent::request so no real API call is made.
# ---------------------------------------------------------------------------

use Test::Most;
use Test::Mojo;
use File::Spec ();
use Mojo::Util qw(url_escape);
use JSON::PP    ();

my $t = Test::Mojo->new('Database::BI');

use_ok('Database::BI::Ask');

# ---------------------------------------------------------------------------
# Section 1: infer_column_types
# ---------------------------------------------------------------------------

{
	my $records = [
		{ amount => '12.5',   region => 'North', date => '2026-01-01' },
		{ amount => '99.0',   region => 'South', date => '2026-02-01' },
		{ amount => '3.14',   region => 'East',  date => '2026-03-01' },
	];
	my $cols    = [qw(amount region date)];
	my $typed   = Database::BI::Ask::infer_column_types($records, $cols);

	is(ref $typed, 'ARRAY', 'infer_column_types returns arrayref');
	is(scalar @$typed, 3, 'one entry per column');

	my %by_name = map { $_->{name} => $_->{type} } @$typed;
	is($by_name{amount}, 'number', 'numeric column detected');
	is($by_name{region}, 'string', 'string column detected');
	is($by_name{date},   'date',   'ISO date column detected');
}

{
	my $records = [
		{ d => '1/15/2026', n => '(100.00)' },
		{ d => '2/03/2026', n => '(200.50)' },
	];
	my $typed = Database::BI::Ask::infer_column_types($records, ['d', 'n']);
	my %by = map { $_->{name} => $_->{type} } @$typed;
	is($by{d}, 'date',   'M/D/YYYY date detected');
	# accounting-notation parens are not plain numbers; type depends on looks_like_number
	# (it returns false for parens); accounting cols classify as string here, which is fine
	# -- the LLM still gets the right context from the column name.
}

{
	my $typed = Database::BI::Ask::infer_column_types([], []);
	is(ref $typed, 'ARRAY', 'empty input returns arrayref');
	is(scalar @$typed, 0, 'empty input returns empty list');
}

{
	my $typed = Database::BI::Ask::infer_column_types(undef, undef);
	is(ref $typed, 'ARRAY', 'undef inputs return arrayref');
}

# ---------------------------------------------------------------------------
# Section 2: ask() guard conditions (no LLM call needed)
# ---------------------------------------------------------------------------

{
	my $r = Database::BI::Ask::ask(
		question  => '',
		spec_key  => 'table:sales',
		columns   => [],
		ai_config => { api_key => 'k' },
	);
	is($r->{error}, 'ask_no_question', 'empty question -> ask_no_question');
}

{
	my $r = Database::BI::Ask::ask(
		question  => 'show me sales',
		spec_key  => 'table:sales',
		columns   => [],
		ai_config => {},
	);
	is($r->{error}, 'ask_unavailable', 'no api_key -> ask_unavailable');
}

{
	my $r = Database::BI::Ask::ask(
		question  => 'show me sales',
		spec_key  => 'table:sales',
		columns   => [],
		ai_config => { api_key => '' },
	);
	is($r->{error}, 'ask_unavailable', 'empty api_key -> ask_unavailable');
}

# ---------------------------------------------------------------------------
# Section 3: ask() with mocked LLM responses
# ---------------------------------------------------------------------------

sub mock_llm_response {
	my ($json_text) = @_;
	require LWP::UserAgent;
	require HTTP::Response;
	my $resp_body = JSON::PP::encode_json({
		content => [{ type => 'text', text => $json_text }],
	});
	return sub {
		my ($self, $req) = @_;
		return HTTP::Response->new(200, 'OK', ['Content-Type' => 'application/json'], $resp_body);
	};
}

sub mock_llm_failure {
	my ($status) = @_;
	$status //= 500;
	require LWP::UserAgent;
	require HTTP::Response;
	return sub {
		my ($self, $req) = @_;
		return HTTP::Response->new($status, 'Error', [], '');
	};
}

my @COLS = (
	{ name => 'region', type => 'string' },
	{ name => 'amount', type => 'number' },
	{ name => 'date',   type => 'date'   },
);

# --- pie chart ---
{
	local *LWP::UserAgent::request = mock_llm_response(
		'{"kind":"pie","title":"Sales by region","encode":{"cat":"region","val":"amount"}}'
	);
	my $r = Database::BI::Ask::ask(
		question  => 'show me sales by region as a pie chart',
		spec_key  => 'table:sales',
		label     => 'sales',
		columns   => \@COLS,
		ai_config => { api_key => 'test-key' },
	);
	is($r->{valid}, 1, 'pie: valid=1');
	is($r->{url}, '/pie?l=table%3Asales&cat=region&val=amount', 'pie: correct URL');
	is($r->{spec}{name}, 'Sales by region', 'pie: spec name from title');
	is($r->{spec}{visuals}[0]{kind}, 'pie', 'pie: kind in spec');
}

# --- bar chart ---
{
	local *LWP::UserAgent::request = mock_llm_response(
		'{"kind":"bar","title":"Top regions","encode":{"cat":"region","val":"amount"}}'
	);
	my $r = Database::BI::Ask::ask(
		question  => 'bar chart of amount per region',
		spec_key  => 'table:sales',
		label     => 'sales',
		columns   => \@COLS,
		ai_config => { api_key => 'test-key' },
	);
	is($r->{valid}, 1, 'bar: valid=1');
	like($r->{url}, qr{^/bar\?}, 'bar: URL starts with /bar');
}

# --- line/graph chart (kind=line maps to /graph) ---
{
	local *LWP::UserAgent::request = mock_llm_response(
		'{"kind":"line","title":"Amount over time","encode":{"x":"date","y":"amount"}}'
	);
	my $r = Database::BI::Ask::ask(
		question  => 'show amount over time',
		spec_key  => 'table:sales',
		label     => 'sales',
		columns   => \@COLS,
		ai_config => { api_key => 'test-key' },
	);
	is($r->{valid}, 1, 'line: valid=1');
	like($r->{url}, qr{^/graph\?}, 'line kind maps to /graph route');
}

# --- histogram ---
{
	local *LWP::UserAgent::request = mock_llm_response(
		'{"kind":"histogram","title":"Amount distribution","encode":{"col":"amount"}}'
	);
	my $r = Database::BI::Ask::ask(
		question  => 'distribution of amount',
		spec_key  => 'table:sales',
		label     => 'sales',
		columns   => \@COLS,
		ai_config => { api_key => 'test-key' },
	);
	is($r->{valid}, 1, 'histogram: valid=1');
	like($r->{url}, qr{^/histogram\?}, 'histogram: correct route');
	like($r->{url}, qr{col=amount},    'histogram: col param present');
}

# --- scatter ---
{
	local *LWP::UserAgent::request = mock_llm_response(
		'{"kind":"scatter","title":"Region vs amount","encode":{"x":"region","y":"amount"}}'
	);
	my $r = Database::BI::Ask::ask(
		question  => 'scatter plot',
		spec_key  => 'table:sales',
		label     => 'sales',
		columns   => \@COLS,
		ai_config => { api_key => 'test-key' },
	);
	is($r->{valid}, 1, 'scatter: valid=1');
	like($r->{url}, qr{^/scatter\?}, 'scatter: correct route');
}

# --- table kind -> /view/<table> ---
{
	local *LWP::UserAgent::request = mock_llm_response(
		'{"kind":"table","title":"Show the data","encode":{}}'
	);
	my $r = Database::BI::Ask::ask(
		question  => 'show the raw data',
		spec_key  => 'table:sales',
		label     => 'sales',
		columns   => \@COLS,
		ai_config => { api_key => 'test-key' },
	);
	is($r->{valid}, 1, 'table kind: valid=1');
	is($r->{url}, '/view/sales', 'table kind: URL is /view/<table>');
}

# --- table kind with path: spec -> /open?path=... ---
{
	local *LWP::UserAgent::request = mock_llm_response(
		'{"kind":"table","title":"Show the data","encode":{}}'
	);
	my $r = Database::BI::Ask::ask(
		question  => 'show the raw data',
		spec_key  => 'path:/tmp/data.csv',
		label     => 'data',
		columns   => \@COLS,
		ai_config => { api_key => 'test-key' },
	);
	is($r->{valid}, 1, 'table/path: valid=1');
	like($r->{url}, qr{^/open\?path=}, 'table/path: URL is /open?path=');
}

# --- LLM response has surrounding text (should still parse) ---
{
	local *LWP::UserAgent::request = mock_llm_response(
		"Here is the JSON:\n"
		. '{"kind":"pie","title":"Sales by region","encode":{"cat":"region","val":"amount"}}'
		. "\nHope that helps!"
	);
	my $r = Database::BI::Ask::ask(
		question  => 'pie chart',
		spec_key  => 'table:sales',
		label     => 'sales',
		columns   => \@COLS,
		ai_config => { api_key => 'test-key' },
	);
	is($r->{valid}, 1, 'fallback JSON extraction works when LLM wraps with text');
}

# --- column not in dataset -> ask_invalid_spec ---
{
	local *LWP::UserAgent::request = mock_llm_response(
		'{"kind":"bar","title":"Bad column","encode":{"cat":"nonexistent_col","val":"amount"}}'
	);
	my $r = Database::BI::Ask::ask(
		question  => 'bar chart',
		spec_key  => 'table:sales',
		label     => 'sales',
		columns   => \@COLS,
		ai_config => { api_key => 'test-key' },
	);
	like($r->{error}, qr/^ask_invalid_spec:/, 'bad column -> ask_invalid_spec error');
	like($r->{error}, qr/nonexistent_col/,    'error names the bad column');
}

# --- bad kind -> ask_unparseable ---
{
	local *LWP::UserAgent::request = mock_llm_response(
		'{"kind":"unknown_kind","title":"Oops","encode":{}}'
	);
	my $r = Database::BI::Ask::ask(
		question  => 'something',
		spec_key  => 'table:sales',
		label     => 'sales',
		columns   => \@COLS,
		ai_config => { api_key => 'test-key' },
	);
	is($r->{error}, 'ask_unparseable', 'unknown kind -> ask_unparseable');
}

# --- non-JSON response -> ask_unparseable ---
{
	local *LWP::UserAgent::request = mock_llm_response('This is not JSON at all!');
	my $r = Database::BI::Ask::ask(
		question  => 'something',
		spec_key  => 'table:sales',
		label     => 'sales',
		columns   => \@COLS,
		ai_config => { api_key => 'test-key' },
	);
	is($r->{error}, 'ask_unparseable', 'non-JSON response -> ask_unparseable');
}

# --- provider returns 500 -> ask_provider_error ---
{
	local *LWP::UserAgent::request = mock_llm_failure(500);
	my $r = Database::BI::Ask::ask(
		question  => 'something',
		spec_key  => 'table:sales',
		label     => 'sales',
		columns   => \@COLS,
		ai_config => { api_key => 'test-key' },
	);
	is($r->{error}, 'ask_provider_error', '500 from provider -> ask_provider_error');
}

# --- spec datasets and version ---
{
	local *LWP::UserAgent::request = mock_llm_response(
		'{"kind":"pie","title":"Sales by region","encode":{"cat":"region","val":"amount"}}'
	);
	my $r = Database::BI::Ask::ask(
		question  => 'pie chart',
		spec_key  => 'table:sales',
		label     => 'sales',
		columns   => \@COLS,
		ai_config => { api_key => 'test-key' },
	);
	is(ref $r->{spec}{datasets}, 'ARRAY', 'spec has datasets array');
	is($r->{spec}{datasets}[0]{spec}, 'table:sales', 'spec dataset has correct spec_key');
	is($r->{spec}{version}, 1, 'spec version=1');
}

# ---------------------------------------------------------------------------
# Section 4: URL construction correctness
# ---------------------------------------------------------------------------

{
	# spec_key with special chars must be percent-encoded
	local *LWP::UserAgent::request = mock_llm_response(
		'{"kind":"pie","title":"T","encode":{"cat":"region"}}'
	);
	my $r = Database::BI::Ask::ask(
		question  => 'q',
		spec_key  => 'path:/my data/file.csv',
		columns   => [{ name => 'region', type => 'string' }],
		ai_config => { api_key => 'k' },
	);
	is($r->{valid}, 1, 'URL build: valid');
	# path:/my data/file.csv -> l=path%3A%2Fmy%20data%2Ffile.csv
	like($r->{url}, qr{l=path%3A}, 'URL build: colon percent-encoded in l=');
	like($r->{url}, qr{%20},       'URL build: space percent-encoded');
}

# ---------------------------------------------------------------------------
# Section 5: HTTP endpoint tests (no ai_api_key configured -> 503)
# ---------------------------------------------------------------------------

{
	# Without ai_api_key the app returns 503
	$t->post_ok('/api/ask', form => { l => 'table:sales', q => 'test' })
	  ->status_is(503)
	  ->json_like('/error', qr/not available/i);
}

# ---------------------------------------------------------------------------
# Section 6: HTTP -- missing parameter guards
# ---------------------------------------------------------------------------

{
	# Set a fake ai_api_key so the endpoint proceeds past the 503 guard
	my $saved = $t->app->config->{ai_api_key};
	$t->app->config->{ai_api_key} = 'fake-test-key';

	$t->post_ok('/api/ask', form => { q => 'test question' })
	  ->status_is(400)
	  ->json_like('/error', qr/l/i, 'missing l= -> 400');

	$t->post_ok('/api/ask', form => { l => 'table:sales' })
	  ->status_is(400)
	  ->json_like('/error', qr/question/i, 'missing q= -> 400');

	# Restore
	if (defined $saved) {
		$t->app->config->{ai_api_key} = $saved;
	} else {
		delete $t->app->config->{ai_api_key};
	}
}

# ---------------------------------------------------------------------------
# Section 7: HTTP -- valid request with mocked LWP
# ---------------------------------------------------------------------------

SKIP: {
	skip 'data/sales.csv not found', 5 unless -f 'data/sales.csv';

	my $saved = $t->app->config->{ai_api_key};
	$t->app->config->{ai_api_key} = 'fake-test-key';

	{
		local *LWP::UserAgent::request = mock_llm_response(
			'{"kind":"bar","title":"Sales by region","encode":{"cat":"region","val":"amount"}}'
		);
		$t->post_ok('/api/ask', form => { l => 'table:sales', q => 'bar chart' })
		  ->status_is(200)
		  ->json_is('/valid', 1)
		  ->json_like('/url', qr{^/bar\?})
		  ->json_like('/spec/name', qr/Sales by region/);
	}

	if (defined $saved) {
		$t->app->config->{ai_api_key} = $saved;
	} else {
		delete $t->app->config->{ai_api_key};
	}
}

# ---------------------------------------------------------------------------
# Section 8: Dashboard shows btn-ask when ai_available, absent otherwise
# ---------------------------------------------------------------------------

{
	my $saved = $t->app->config->{ai_api_key};
	delete $t->app->config->{ai_api_key};

	$t->get_ok('/view/sales')
	  ->status_is(200)
	  ->content_unlike(qr/id="btn-ask"/, 'btn-ask absent when no ai_api_key');

	$t->app->config->{ai_api_key} = 'fake-key';
	$t->get_ok('/view/sales')
	  ->status_is(200)
	  ->content_like(qr/id="btn-ask"/, 'btn-ask present when ai_api_key set');

	if (defined $saved) {
		$t->app->config->{ai_api_key} = $saved;
	} else {
		delete $t->app->config->{ai_api_key};
	}
}

done_testing;
