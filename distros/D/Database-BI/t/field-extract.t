use strict;
use warnings;

use Test::More;
use Test::Mojo;
use Mojo::DOM  ();
use Mojo::File ();
use Mojo::JSON qw(encode_json);
use File::Temp ();
use Mojo::Util qw(url_escape);
use DBI ();

use Database::BI::Calc ();
use Database::BI::Controller::Dashboard ();

# ---------------------------------------------------------------------------
# Field extraction -- Phase 7 item 7.4a.  (Not t/extract.t, which covers the
# Extract.pm cache.)
#
# Two forms: rx(col, 'pattern', 'group') inside c=, one capture and one value;
# and a stored extraction, extractions.<spec>.<name> in models.json, whose
# named groups each become a column.  Both compile through
# Calc::compile_pattern, so they refuse the same patterns.  These tests follow
# the acceptance list in BI-Phase-7.md section 7a.
#
#   prove -l t/field-extract.t
# ---------------------------------------------------------------------------

# --- the primitive ---------------------------------------------------------

subtest 'compile_pattern' => sub {
	my $c = Database::BI::Calc::compile_pattern('^(?<cc>[A-Z]{2})-(\d+)-(?<n>\d+)');
	is $c->{groups}, 3, 'it counts every capture group';
	is_deeply $c->{names}, [qw(cc n)], 'and lists the named ones in the order they are written';
	isa_ok $c->{re}, 'Regexp';

	my @refused = (
		[ '(?{ 1 })',   '(?{'  ],
		[ 'a(??{ 1 })', '(??{' ],
		[ '(?p)a',      '(?p'  ],
		[ '(*FAIL)',    '(*'   ],
		[ '\\\\(*FAIL)', '(*', 'after an escaped backslash the paren is real' ],
	);
	for my $case (@refused) {
		my ($p, $what, $why) = @$case;
		my $ok = eval { Database::BI::Calc::compile_pattern($p); 1 };
		ok !$ok, $why // "$p is refused";
		like $@, qr/\APattern '\Q$p\E' uses \Q$what\E, which is not allowed/, "and says it uses $what";
	}
	ok eval { Database::BI::Calc::compile_pattern('\\(*x'); 1 }, 'an escaped paren is a literal, and allowed';

	ok !eval { Database::BI::Calc::compile_pattern('(a'); 1 }, 'a pattern that does not compile';
	like $@, qr/\APattern '\(a' does not compile: Unmatched \(/, 'is refused with perl\'s reason';

	ok !eval { Database::BI::Calc::compile_pattern('a' x 201); 1 }, 'a pattern of 201 characters';
	like $@, qr/is longer than 200 characters/, 'is too long';
	ok eval { Database::BI::Calc::compile_pattern('a' x 200); 1 }, 'and one of 200 is not';

	$@ = 'theirs';
	Database::BI::Calc::compile_pattern('x');
	is $@, 'theirs', 'the caller\'s $@ survives';
};

subtest 'capture_of' => sub {
	my $c = Database::BI::Calc::compile_pattern('^(?<cc>[A-Z]{2})-(\d+)(x)?');
	my $cap = \&Database::BI::Calc::capture_of;
	is $cap->($c, 'GB-12', 1), 'GB', 'a group by number';
	is $cap->($c, 'GB-12', 'cc'), 'GB', 'and by name';
	is $cap->($c, 'GB-12', 2), '12', 'an unnamed group';
	is $cap->($c, 'GB-12', 3), '', 'a group that took no part is empty';
	is $cap->($c, 'nope', 1), undef, 'no match is undef';
	is $cap->($c, undef, 1), undef, 'so is no value';
	is $cap->($c, 'GB-12', 4), undef, 'and a group the pattern does not have';
	is $cap->($c, 'GB-12', 0), undef, 'group 0 is not a group';
	is $cap->($c, 'GB-12', 'zz'), undef, 'nor is an unknown name';
	my $long = Database::BI::Calc::compile_pattern('(.*)');
	is length($cap->($long, 'y' x 500, 1)), 200, 'a capture is cut to 200 characters';
};

subtest 'rx() in a calculated field' => sub {
	my $eval = sub {
		my ($expr, $value) = @_;
		my $calc = Database::BI::Calc->new(expr => $expr, columns => ['ref']);
		return $calc->has_error ? 'ERROR: ' . $calc->error : $calc->evaluate({ ref => $value });
	};
	is $eval->(q{rx(ref,'^([A-Z]{2})-','1')}, 'GB-123'), 'GB', 'the POD example';
	is $eval->(q{rx(ref,'^([A-Z]{2})-')}, 'GB-123'), 'GB', 'the group defaults to the first';
	is $eval->(q{rx(ref,'-(?<num>\d+)$','num')}, 'GB-123'), '123', 'a named group';
	is $eval->(q{rx(ref,'-(\d+)$',2)}, 'GB-123'), undef, 'a bad group is undef, not a croak';
	is $eval->(q{rx(ref,'^Q')}, 'GB-123'), undef, 'a pattern that does not match is undef';
	is $eval->(q{upper(rx(ref,'-([a-z]+)'))}, 'GB-abc'), 'ABC', 'and it composes';
	like $eval->(q{rx(ref,'(?{1})')}, 'x'), qr/^ERROR: Pattern '\(\?\{1\}\)' uses/, 'a refused construct is a compile error';
	like $eval->(q{rx(ref,'(a')}, 'x'), qr/^ERROR: Pattern '\(a' does not compile/, 'as is a malformed pattern';
	like $eval->(q{rx(ref)}, 'x'), qr/^ERROR: rx\(\) takes a column/, 'it needs a pattern';
	like $eval->(q{rx(ref,ref)}, 'x'), qr/^ERROR: rx\(\) takes a column/, 'which is a quoted constant';
};

# --- the routes ------------------------------------------------------------

my $data_dir  = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1));
my $model_dir = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1))->to_string;

$data_dir->child('invoices.csv')->spew(join("\n",
	'id,ref,amount,cc',
	'1,GB-2026-001,10,x',
	'2,GB-2026-002,20,x',
	'3,FR-2025-001,30,x',
	'4,unknown,40,x',
) . "\n");

my $t = Test::Mojo->new('Database::BI', { data_dir => $data_dir->to_string, model_dir => $model_dir });
$t->app->log->level('fatal');

my $L   = 'table:invoices';
my $INV = 'l=' . url_escape($L);
my $PAT = '^(?<country>[A-Z]{2})-(?<year>\d{4})-';

sub _csv {
	my @lines = split /\r?\n/, $_[0];
	my @names = split /,/, shift(@lines) // '';
	return map { my %r; @r{@names} = split /,/, $_, -1; \%r } @lines;
}

sub _export {
	my $q = join '&', $INV, 'format=csv', @_;
	$t->get_ok("/export?$q")->status_is(200);
	return _csv($t->tx->res->body);
}

sub _save {
	my (%form) = @_;
	return $t->post_ok('/extract/save' => form => { l => $L, %form })->tx->res->json;
}

subtest 'rx() on a route' => sub {
	my %code = map { $_->{id} => $_->{code} } _export('c=' . url_escape(q{code:rx(ref,'^([A-Z]{2})-','1')}));
	is_deeply [ @code{1 .. 4} ], [ 'GB', 'GB', 'FR', '(unparseable)' ], 'a row it does not match is (unparseable)';
	$t->get_ok("/export?$INV&format=csv&c=" . url_escape(q{code:rx(ref,'(*FAIL)')}))->status_is(400)
		->content_like(qr/uses \(\*, which is not allowed/, 'a refused construct is a 400');
	$t->get_ok("/export?$INV&format=csv&c=" . url_escape(q{code:rx(ref,'(a')}))->status_is(400)
		->content_like(qr/Pattern '\(a' does not compile/, 'as is a malformed pattern, named');
};

subtest 'the routes refuse what they cannot store' => sub {
	$t->get_ok('/extract/list')->status_is(400)->json_is('/error', 'l= required');
	$t->post_ok('/extract/save')->status_is(400)->json_is('/error', 'l= required');
	$t->post_ok('/extract/delete')->status_is(400)->json_is('/error', 'l= required');
	_save(name => '1x', col => 'ref', pattern => $PAT);
	$t->status_is(400)->json_like('/error', qr/Extraction name "1x" is not a valid identifier/);
	_save(name => 'parts', pattern => $PAT);
	$t->status_is(400)->json_is('/error', 'col= required');
	_save(name => 'parts', col => 'ref');
	$t->status_is(400)->json_is('/error', 'pattern= required');

	for my $case (
		[ 'a malformed pattern',   '(?<x>a',          qr/Extraction "parts": Pattern '\(\?<x>a' does not compile/ ],
		[ 'a refused construct',   '(?<x>a)(?{1})',   qr/Extraction "parts": Pattern .* uses \(\?\{, which is not allowed/ ],
		[ 'a pattern too long',    '(?<x>a)' . ('b' x 200), qr/is longer than 200 characters/ ],
		[ 'no named group',        '^([A-Z]{2})-',    qr/the pattern names no group/ ],
	) {
		my ($name, $pattern, $re) = @$case;
		_save(name => 'parts', col => 'ref', pattern => $pattern);
		$t->status_is(400, "$name is a 400")->json_like('/error', $re, "$name says why");
	}
	_save(name => 'parts', col => 'ref', pattern => $PAT, fields => 'country,nope');
	$t->status_is(400)->json_like('/error', qr/has no group named "nope"/, 'a field that is not a group');
	$t->get_ok("/extract/list?$INV")->json_is('/extractions', {}, 'and nothing was stored');
};

subtest 'two captures become two columns, in the export and a pivot' => sub {
	my $json = _save(name => 'parts', col => 'ref', pattern => $PAT);
	$t->status_is(200);
	is_deeply $json, { ok => 1, fields => [qw(country year)] }, 'the save names the columns it will add';
	$t->get_ok("/extract/list?$INV")->json_is('/extractions/parts',
		{ col => 'ref', pattern => $PAT, fields => [qw(country year)] });

	my %row = map { $_->{id} => $_ } _export();
	is_deeply [ map { $row{$_}{country} } 1 .. 4 ], [ 'GB', 'GB', 'FR', '(unparseable)' ], 'country';
	is_deeply [ map { $row{$_}{year} } 1 .. 4 ], [ '2026', '2026', '2025', '(unparseable)' ], 'and year';

	$t->get_ok("/pivot?$INV&rows=country&cols=year&m=" . url_escape('amount:sum:total'))->status_is(200);
	my $body = $t->tx->res->body;
	like $body, qr{<td[^>]*>GB</td>}, 'the pivot groups by one';
	like $body, qr{<td[^>]*>\(unparseable\)</td>}, 'and the rows that did not match group visibly';
	like $body, qr{<th colspan="1">2025\s*</th>}, 'with the other across';

	my @gb = _export('f=' . url_escape('country:eq:GB'));
	is_deeply [ sort map { $_->{id} } @gb ], [ 1, 2 ], 'a filter on an extracted column';

	$t->get_ok('/view/invoices')->status_is(200)->content_like(qr{<td[^>]*>FR</td>}, 'the table shows it');
	$t->get_ok("/stats?$INV")->status_is(200)->content_like(qr/\bcountry\b/, 'and the stats page');

	my %half = map { $_->{id} => $_->{y1} } _export('c=' . url_escape('y1:year+1'));
	is $half{3}, 2026, 'a calculated field reads one';
};

subtest 'a name the dataset has is prefixed; a source column is kept' => sub {
	_save(name => 'cc', col => 'ref', pattern => '^(?<cc>[A-Z]{2})');
	$t->status_is(200);
	my ($one) = grep { $_->{id} == 1 } _export();
	is $one->{cc}, 'x', 'the source column cc is untouched';
	is $one->{cc_cc}, 'GB', 'and the group lands as <extraction>_<group>';
	$t->post_ok('/extract/delete' => form => { l => $L, name => 'cc' })->status_is(200)->json_is('/ok', 1);
	$t->get_ok("/extract/list?$INV")->json_hasnt('/extractions/cc')->json_has('/extractions/parts');
};

subtest 'fields= picks some of the groups' => sub {
	_save(name => 'parts', col => 'ref', pattern => $PAT, fields => 'year');
	$t->status_is(200)->json_is('/fields', ['year']);
	my @rows = _export();
	ok exists $rows[0]{year}, 'the group named is added';
	ok !exists $rows[0]{country}, 'and the other is not';
	_save(name => 'parts', col => 'ref', pattern => $PAT);
};

subtest 'a column the dataset lacks is a 400' => sub {
	_save(name => 'gone', col => 'nope', pattern => '(?<x>.)');
	$t->status_is(200);
	$t->get_ok("/export?$INV&format=csv")->status_is(400)
		->content_like(qr/Extraction "gone": column "nope" is not in this dataset/);
	$t->post_ok('/extract/delete' => form => { l => $L, name => 'gone' })->status_is(200);
};

subtest 'an extraction applies to a canvas card' => sub {
	my $id = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Extraction canvas',
			datasets => [ { spec => $L, alias => 'left' } ],
			visuals  => [ { kind => 'bar', title => 'By country', encode => { cat => 'country', value => 'amount' } } ],
		}),
	)->status_is(201)->tx->res->json->{id};
	$t->get_ok("/a/$id")->status_is(200)->content_like(qr/FR/, 'the card is drawn from the column');
	my $dom = Mojo::DOM->new($t->tx->res->body);
	ok $dom->at('#visual-0'), 'the card is on the page';
	ok !$dom->at('#visual-0 .visual-error'), 'with no error';
};

subtest 'an extracted group on a SQLite source folds in Perl' => sub {
	plan skip_all => 'DBD::SQLite is not available' unless eval { require DBD::SQLite; 1 };
	my $dbh = DBI->connect('dbi:SQLite:dbname=' . $data_dir->child('ledger.sqlite'),
		'', '', { RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE ledger (id INTEGER PRIMARY KEY, ref TEXT, amount REAL)');
	$dbh->do('INSERT INTO ledger VALUES (?,?,?)', undef, @$_) for
		[ 1, 'GB-1', 10 ], [ 2, 'FR-2', 20 ], [ 3, 'GB-3', 30 ];
	$dbh->disconnect;
	my $ls = 'table:ledger';
	$t->post_ok('/extract/save' => form => { l => $ls, name => 'p', col => 'ref', pattern => '^(?<cc>[A-Z]+)' })
		->status_is(200);

	require Database::BI::Model::DataSource;
	my $pushed = 0;
	my $real   = \&Database::BI::Model::DataSource::aggregate;
	no warnings 'redefine';
	local *Database::BI::Model::DataSource::aggregate = sub { $pushed++; return $real->(@_) };

	my $cells = sub {
		$t->get_ok($_[0])->status_is(200);
		return [ map { $_->all_text =~ s/\s+//gr }
			@{ Mojo::DOM->new($t->tx->res->body)->find('table tbody td')->to_array } ];
	};
	my $q = '/pivot?l=' . url_escape($ls) . '&rows=cc&m=' . url_escape('amount:sum:total');
	my $page = $cells->($q);
	is $pushed, 0, 'an extracted column as the group never reaches aggregate()';
	is_deeply $page, [ 'FR', 20, 'GB', 40 ], 'and the totals are right';
	local $ENV{BI_FORCE_PERL_AGG} = 1;
	is_deeply $cells->($q), $page, 'the same with the fold forced';
	$t->get_ok('/view/ledger')->status_is(200)->content_like(qr{<td[^>]*>FR</td>},
		'the locked rows of a SQL source take the column');
};

subtest 'delete without name= clears the dataset' => sub {
	$t->post_ok('/extract/delete' => form => { l => $L })->status_is(200);
	$t->get_ok("/extract/list?$INV")->json_is('/extractions', {});
	ok !exists +(_export())[0]{country}, 'and the columns are gone';
};

done_testing;
