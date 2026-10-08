#!perl -w

use strict;
use warnings;

use FindBin qw($Bin);
use File::Spec;
use Test::Most tests => 26;
use Test::NoWarnings;
use Test::Mockingbird;
use Test::Returns;
use HTTP::Response;

# Pre-load the modules that _open() lazy-requires so that mock() can install
# its replacements before require() runs inside the code under test.  Without
# this, the first require LWP::UserAgent inside _open() would overwrite the
# mock that was installed before the object's first query.
use LWP::UserAgent;
require HTML::TableExtract;

use lib 't/lib';
use Database::test1;

# ---------------------------------------------------------------------------
# Helpers — build canned HTTP responses served by all mocks below
# ---------------------------------------------------------------------------

my $DATA_DIR  = File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');
my $HTML_FILE = File::Spec->catfile($DATA_DIR, 'test1.html');

open(my $fh, '<', $HTML_FILE) or die "Cannot open $HTML_FILE: $!";
my $FIXTURE_HTML = do { local $/; <$fh> };
close $fh;

sub make_ok_response {
	my ($html) = @_;
	my $r = HTTP::Response->new(200, 'OK');
	$r->content_type('text/html; charset=UTF-8');
	$r->content($html);
	return $r;
}

sub make_fail_response {
	return HTTP::Response->new(404, 'Not Found');
}

# ---------------------------------------------------------------------------
# 1. Basic keyed slurp from a URL
# ---------------------------------------------------------------------------
{
	my $g = mock_scoped 'LWP::UserAgent::get' => sub { make_ok_response($FIXTURE_HTML) };

	my $db = new_ok('Database::test1' => [{ url => 'http://example.com/test1.html' }]);

	# _open is lazy; trigger it before checking type
	returns_is($db->count(), { type => 'integer', min => 3, max => 3 }, 'count returns 3 data rows');
	is($db->{'type'}, 'HTML', 'type is HTML');

	my $row = $db->fetchrow_hashref(entry => '1');
	returns_is($row, { type => 'hashref' }, 'fetchrow_hashref finds entry 1');
	is($row->{'name'}, 'Alice', 'name is Alice');
	is($row->{'age'}, '30', 'age is 30');

	my $row2 = $db->fetchrow_hashref(entry => '2');
	is($row2->{'name'}, 'Bob', 'name is Bob');

	my $missing = $db->fetchrow_hashref(entry => '99');
	returns_is($missing, { type => 'void' }, 'missing entry returns undef');
}

# ---------------------------------------------------------------------------
# 2. selectall_arrayref — all rows and filtered rows
# ---------------------------------------------------------------------------
{
	my $g = mock_scoped 'LWP::UserAgent::get' => sub { make_ok_response($FIXTURE_HTML) };

	my $db = Database::test1->new(url => 'http://example.com/test1.html');

	my $all = $db->selectall_arrayref();
	returns_is($all, { type => 'arrayref', min => 3, max => 3 }, 'selectall_arrayref returns 3-row arrayref');

	my $filtered = $db->selectall_arrayref(name => 'Bob');
	returns_is($filtered, { type => 'arrayref', min => 1, max => 1 }, 'filter by name=Bob finds 1 row');
	is($filtered->[0]{'name'}, 'Bob', 'filtered row is Bob');
}

# ---------------------------------------------------------------------------
# 3. AUTOLOAD column lookup
# ---------------------------------------------------------------------------
{
	my $g = mock_scoped 'LWP::UserAgent::get' => sub { make_ok_response($FIXTURE_HTML) };

	my $db = Database::test1->new(url => 'http://example.com/test1.html');

	is($db->name(entry => '1'), 'Alice', 'AUTOLOAD name lookup for entry 1');
	is($db->name(entry => '3'), 'Charlie', 'AUTOLOAD name lookup for entry 3');
}

# ---------------------------------------------------------------------------
# 4. html_table_index — select the second table on the page
# ---------------------------------------------------------------------------
{
	my $g = mock_scoped 'LWP::UserAgent::get' => sub { make_ok_response($FIXTURE_HTML) };

	my $db = Database::test1->new(url => 'http://example.com/test1.html', no_entry => 1, html_table_index => 1);

	my $rows = $db->selectall_arrayref();
	is($db->{'type'}, 'HTML', 'type is HTML for table index 1');
	returns_is($rows, { type => 'arrayref', min => 2, max => 2 }, 'second table has 2 data rows');
	is($rows->[0]{'colour'}, 'red', 'first row colour is red');
	is($rows->[1]{'hex'}, '#00ff00', 'second row hex is #00ff00');
}

# ---------------------------------------------------------------------------
# 5. no_entry mode — row list without a key column
# ---------------------------------------------------------------------------
{
	my $g = mock_scoped 'LWP::UserAgent::get' => sub { make_ok_response($FIXTURE_HTML) };

	my $db = Database::test1->new(url => 'http://example.com/test1.html', no_entry => 1);
	my $rows = $db->selectall_arrayref();
	returns_is($rows, { type => 'arrayref', min => 3, max => 3 }, 'no_entry mode returns 3 rows');
	ok(exists $rows->[0]{'entry'}, 'entry column is present in no_entry mode');
}

# ---------------------------------------------------------------------------
# 6. HTTP failure croaks with a clear message
# ---------------------------------------------------------------------------
{
	my $g = mock_scoped 'LWP::UserAgent::get' => sub { make_fail_response() };

	throws_ok {
		Database::test1->new(url => 'http://example.com/missing.html')
			->selectall_arrayref();
	} qr/cannot fetch/, 'HTTP 404 causes a croak';
}

# ---------------------------------------------------------------------------
# 7. out-of-range html_table_index croaks
# ---------------------------------------------------------------------------
{
	my $g = mock_scoped 'LWP::UserAgent::get' => sub { make_ok_response($FIXTURE_HTML) };

	throws_ok {
		Database::test1->new(url => 'http://example.com/test1.html', html_table_index => 99)
			->selectall_arrayref();
	} qr/html_table_index 99 out of range/, 'out-of-range table index croaks';
}

# ---------------------------------------------------------------------------
# 8. URL validation in new() — non-http scheme rejected immediately
# ---------------------------------------------------------------------------
{
	throws_ok {
		Database::test1->new(url => 'ftp://example.com/data.html');
	} qr/unsafe url/, 'ftp:// URL is rejected';

	throws_ok {
		Database::test1->new(url => 'file:///etc/passwd');
	} qr/unsafe url/, 'file:// URL is rejected';

	throws_ok {
		Database::test1->new(url => 'javascript:alert(1)');
	} qr/unsafe url/, 'javascript: URL is rejected';
}

# ---------------------------------------------------------------------------
# 9. Repeated calls reuse slurped data (LWP called only once per object)
# ---------------------------------------------------------------------------
{
	my $call_count = 0;
	my $g = mock_scoped 'LWP::UserAgent::get' => sub {
		$call_count++;
		make_ok_response($FIXTURE_HTML);
	};

	my $db = Database::test1->new(url => 'http://example.com/test1.html');
	$db->selectall_arrayref();
	$db->selectall_arrayref();
	$db->count();

	returns_is($call_count, { type => 'integer', min => 1, max => 1 }, 'URL fetched only once per object instance');
}
