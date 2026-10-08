#!perl -w

use strict;
use warnings;

use FindBin qw($Bin);
use File::Spec;
use Test::Needs 'JSON::MaybeXS';
use Test::Most tests => 22;
use Test::NoWarnings;
use Test::Mockingbird;
use Test::Returns;
use HTTP::Response;

# Pre-load both lazy-required modules before any mock is installed.
# Without this, the first require inside _open() would overwrite the mock.
use LWP::UserAgent;
require HTML::TableExtract;

use lib 't/lib';
use Database::test_json_url;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

my $ARRAY_JSON = '[
  {"entry":"1","name":"Alice","grade":"PASS"},
  {"entry":"2","name":"Bob",  "grade":"FAIL"},
  {"entry":"3","name":"Carol","grade":"PASS"}
]';

my $OBJECT_JSON = '{
  "uno": {"colour":"red",  "hex":"#ff0000"},
  "dos": {"colour":"green","hex":"#00ff00"}
}';

my $CPANTESTERS_JSON = '[
  {"dist":"Crypt-SelfCertificate","version":"0.01","grade":"PASS","osname":"linux",  "perl":"5.32.0"},
  {"dist":"Crypt-SelfCertificate","version":"0.01","grade":"FAIL","osname":"mswin32","perl":"5.34.0"},
  {"dist":"Crypt-SelfCertificate","version":"0.01","grade":"PASS","osname":"darwin", "perl":"5.36.0"}
]';

sub json_response {
	my ($body) = @_;
	my $r = HTTP::Response->new(200, 'OK');
	$r->content_type('application/json');
	$r->content($body);
	return $r;
}

sub json_url_response {
	# No explicit application/json Content-Type — detection falls back to URL suffix
	my ($body) = @_;
	my $r = HTTP::Response->new(200, 'OK');
	$r->content_type('text/plain');
	$r->content($body);
	return $r;
}

sub fail_response { HTTP::Response->new(404, 'Not Found') }

# ---------------------------------------------------------------------------
# 1. Content-Type: application/json — array form, keyed on 'entry'
# ---------------------------------------------------------------------------
{
	my $g = mock_scoped 'LWP::UserAgent::get' => sub { json_response($ARRAY_JSON) };

	my $db = new_ok('Database::test_json_url' => [{ url => 'http://example.com/data' }]);

	returns_is($db->count(), { type => 'integer', min => 3, max => 3 }, 'count returns 3 rows from JSON URL');
	is($db->{'type'}, 'JSON', 'type is JSON');

	my $row = $db->fetchrow_hashref(entry => '1');
	returns_is($row, { type => 'hashref' }, 'fetchrow_hashref finds entry 1');
	is($row->{'name'}, 'Alice', 'name is Alice');
	is($row->{'grade'}, 'PASS', 'grade is PASS');

	returns_is($db->fetchrow_hashref(entry => '99'), { type => 'void' }, 'missing entry returns undef');
}

# ---------------------------------------------------------------------------
# 2. selectall_arrayref and filtering
# ---------------------------------------------------------------------------
{
	my $g = mock_scoped 'LWP::UserAgent::get' => sub { json_response($ARRAY_JSON) };

	my $db = Database::test_json_url->new(url => 'http://example.com/data');

	my $all = $db->selectall_arrayref();
	returns_is($all, { type => 'arrayref', min => 3, max => 3 }, 'selectall_arrayref returns 3-row arrayref');

	my $passing = $db->selectall_arrayref(grade => 'PASS');
	returns_is($passing, { type => 'arrayref', min => 2, max => 2 }, 'filter grade=PASS finds 2 rows');
}

# ---------------------------------------------------------------------------
# 3. no_entry mode — array-of-rows without a key column (CPAN Testers style)
# ---------------------------------------------------------------------------
{
	my $g = mock_scoped 'LWP::UserAgent::get' => sub { json_response($CPANTESTERS_JSON) };

	my $db = Database::test_json_url->new(
		url      => 'https://www.cpantesters.org/show/Crypt-SelfCertificate.json',
		no_entry => 1,
	);

	returns_is($db->count(), { type => 'integer', min => 3, max => 3 }, 'CPAN Testers: count returns 3 results');
	is($db->{'type'}, 'JSON', 'CPAN Testers: type is JSON');

	my $rows = $db->selectall_arrayref(grade => 'PASS');
	returns_is($rows, { type => 'arrayref', min => 2, max => 2 }, 'CPAN Testers: 2 PASS results');
	is($rows->[0]{'osname'}, 'linux', 'CPAN Testers: first PASS is linux');
}

# ---------------------------------------------------------------------------
# 4. URL suffix detection — .json suffix triggers JSON path even without
#    an application/json Content-Type header
# ---------------------------------------------------------------------------
{
	my $g = mock_scoped 'LWP::UserAgent::get' => sub { json_url_response($ARRAY_JSON) };

	my $db = Database::test_json_url->new(url => 'http://example.com/data.json');

	returns_is($db->count(), { type => 'integer', min => 3, max => 3 }, '.json URL suffix triggers JSON detection');
	is($db->{'type'}, 'JSON', 'type is JSON for .json URL suffix');
}

# ---------------------------------------------------------------------------
# 5. Object-form JSON — hash keyed by primary-key value
# ---------------------------------------------------------------------------
{
	my $g = mock_scoped 'LWP::UserAgent::get' => sub { json_response($OBJECT_JSON) };

	my $db = Database::test_json_url->new(url => 'http://example.com/colours.json');

	returns_is($db->count(), { type => 'integer', min => 2, max => 2 }, 'object-form JSON: count returns 2');
	my $row = $db->fetchrow_hashref(entry => 'uno');
	returns_is($row, { type => 'hashref' }, 'object-form: fetchrow_hashref finds key "uno"');
	is($row->{'colour'}, 'red', 'object-form: colour is red');
	is($db->hex(entry => 'dos'), '#00ff00', 'AUTOLOAD hex lookup via object-form JSON URL');
}

# ---------------------------------------------------------------------------
# 6. HTTP failure croaks
# ---------------------------------------------------------------------------
{
	my $g = mock_scoped 'LWP::UserAgent::get' => sub { fail_response() };

	throws_ok {
		Database::test_json_url->new(url => 'http://example.com/missing.json')
			->selectall_arrayref();
	} qr/cannot fetch/, 'HTTP 404 causes a croak';
}

# ---------------------------------------------------------------------------
# 7. Repeated calls reuse slurped data (LWP called only once per object)
# ---------------------------------------------------------------------------
{
	my $call_count = 0;
	my $g = mock_scoped 'LWP::UserAgent::get' => sub {
		$call_count++;
		json_response($ARRAY_JSON);
	};

	my $db = Database::test_json_url->new(url => 'http://example.com/data.json');
	$db->selectall_arrayref();
	$db->selectall_arrayref();
	$db->count();

	returns_is($call_count, { type => 'integer', min => 1, max => 1 }, 'URL fetched only once per object instance');
}
