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

use Database::BI::Controller::Dashboard ();

# ---------------------------------------------------------------------------
# Stored lookups -- Phase 7 item 7.3.
#
# A lookup is one file, one key column and one map: lookups.<spec>.<name> in
# models.json, applied at stage 3 of the pipeline so that a filter, a field, a
# bucket or a window can read the columns it adds.  These tests follow the
# acceptance list in BI-Phase-7.md section 6.
#
#   prove -l t/lookup.t
# ---------------------------------------------------------------------------

my $data_dir  = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1));
my $model_dir = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1))->to_string;
my $outside   = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1));

# orders: who bought what, by a shop code.  ZZ is in no lookup row, and " NY "
# carries spaces that the lookup must trim.
$data_dir->child('orders.csv')->spew(join("\n",
	'id,shop,amount,region',
	'1,LDN,10,EU',
	'2,NY ,20,US',
	'3,LDN,30,EU',
	'4,ZZ,40,XX',
) . "\n");

# shops: the lookup file.  LDN appears twice, and the first row must win.  The
# region column clashes with the orders' own.
$data_dir->child('lookups')->make_path;
$data_dir->child('lookups', 'shops.csv')->spew(join("\n",
	'code,city,region',
	'LDN,London,Europe',
	'NY,New York,Americas',
	'LDN,Londres,Elsewhere',
	'ny,lower case,Nowhere',
) . "\n");

$outside->child('secret.csv')->spew("code,city\nLDN,Hidden\n");

my $t = Test::Mojo->new('Database::BI', {
	data_dir  => $data_dir->to_string,
	model_dir => $model_dir,
});

$t->app->log->level('fatal');

my $L      = 'table:orders';
my $ORDERS = 'l=' . url_escape($L);

# _csv($body) -> list of row hashrefs
sub _csv {
	my @lines = split /\r?\n/, $_[0];
	my @names = split /,/, shift(@lines) // '';
	return map { my %r; @r{@names} = split /,/, $_, -1; \%r } @lines;
}

# _export(@query) -> list of row hashrefs from /export as CSV
sub _export {
	my $q = join '&', $ORDERS, 'format=csv', @_;
	$t->get_ok("/export?$q")->status_is(200);
	return _csv($t->tx->res->body);
}

# _save(%form) -> the response JSON of POST /lookups/save
sub _save {
	my (%form) = @_;
	return $t->post_ok('/lookups/save' => form => { l => $L, %form })->tx->res->json;
}

# _logged($code) -> the warn lines logged while $code runs
sub _logged {
	my ($code) = @_;
	my @logged;
	$t->app->log->level('warn');
	my $sub = $t->app->log->on(message => sub { push @logged, $_[2] if $_[1] eq 'warn' });
	$code->();
	$t->app->log->unsubscribe(message => $sub);
	$t->app->log->level('fatal');
	return @logged;
}

subtest 'with no lookup stored, nothing changes' => sub {
	my @rows = _export();
	is_deeply [ sort keys %{ $rows[0] } ], [qw(amount id region shop)], 'the source columns only';
	$t->get_ok("/lookups/list?$ORDERS")->status_is(200)->json_is('/lookups', {});
};

subtest 'the routes refuse what they cannot store' => sub {
	$t->get_ok('/lookups/list')->status_is(400)->json_is('/error', 'l= required');
	$t->post_ok('/lookups/save')->status_is(400)->json_is('/error', 'l= required');
	$t->post_ok('/lookups/delete')->status_is(400)->json_is('/error', 'l= required');

	my $bad = _save(name => '1st', file => 'lookups/shops.csv', key => 'code');
	$t->status_is(400);
	like $bad->{error}, qr/Lookup name "1st"/, 'a name that is not an identifier';

	_save(name => 'shops', file => 'lookups/shops.csv');
	$t->status_is(400)->json_is('/error', 'key= required');

	my $cases = [
		[ 'a file outside data_dir', { file => "$outside/secret.csv" }, qr/is not under data_dir/ ],
		[ 'a walk out of data_dir',  { file => '../' . $outside->basename . '/secret.csv' }, qr/is not under data_dir|not found/ ],
		[ 'a URL',                   { file => 'https://example.com/shops.csv' }, qr/is not a file/ ],
		[ 'another source spec',     { file => 'table:shops' }, qr/is not a file/ ],
		[ 'a remote path',           { file => '/../host/dir/shops.csv' }, qr/is not a file/ ],
		[ 'a missing file',          { file => 'lookups/nope.csv' }, qr/not found/ ],
		[ 'an unsupported file',     { file => 'lookups/' } , qr/not found/ ],
		[ 'a key the file lacks',    { file => 'lookups/shops.csv', key => 'nope' }, qr/key column "nope" is not in "shops.csv"/ ],
		[ 'a field the file lacks',  { file => 'lookups/shops.csv', fields => 'city,nope' }, qr/field "nope" is not in "shops.csv"/ ],
	];
	for my $case (@$cases) {
		my ($name, $form, $re) = @$case;
		my $json = _save(name => 'shops', key => 'code', %$form);
		$t->status_is(400, "$name is a 400");
		like $json->{error} // '', $re, "$name says why";
	}
	$t->get_ok("/lookups/list?$ORDERS")->json_is('/lookups', {}, 'and nothing was stored');
};

subtest 'a symlink inside data_dir cannot reach outside it' => sub {
	plan skip_all => 'no symlinks here' unless eval { symlink "$outside/secret.csv", "$data_dir/link.csv" };
	_save(name => 'linked', file => 'link.csv', key => 'code');
	$t->status_is(400);
	like $t->tx->res->json->{error}, qr/is not under data_dir/, 'the link is followed before the check';
	unlink "$data_dir/link.csv";
};

subtest 'a file too large to be a lookup is refused' => sub {
	my $big = $data_dir->child('big.csv');
	$big->spew("code,city\n" . ("AAAAAAAAAAAAAAA,BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB\n" x 180_000));
	cmp_ok -s $big, '>', 8 * 1_048_576, 'the fixture is over 8 MiB';
	_save(name => 'big', file => 'big.csv', key => 'code');
	$t->status_is(400);
	like $t->tx->res->json->{error}, qr/"big\.csv" is \d+ bytes, more than a lookup may be \(8388608\)/,
		'the message gives the size and the limit';
	$big->remove;
};

subtest 'a stored lookup adds its columns to every route' => sub {
	_save(name => 'shops', file => 'lookups/shops.csv', key => 'code', col => 'shop');
	$t->status_is(200)->json_is('/ok', 1);
	$t->get_ok("/lookups/list?$ORDERS")->status_is(200)
		->json_is('/lookups/shops/file', 'lookups/shops.csv')
		->json_is('/lookups/shops/key', 'code')
		->json_is('/lookups/shops/col', 'shop')
		->json_hasnt('/lookups/shops/fields', 'no fields= stores none, so every column is added');

	my @warned;
	my @rows;
	@warned = _logged(sub { @rows = _export() });

	my %city = map { $_->{id} => $_->{city} } @rows;
	is $city{1}, 'London', 'a key that is in the file takes its row';
	is $city{3}, 'London', 'the first of two rows with one key wins';
	is $city{2}, 'New York', 'the row\'s key is trimmed before it is compared';
	is $city{4}, '', 'a key that is not in the file is undef, not an error';

	my %region = map { $_->{id} => $_ } @rows;
	is $region{1}{region}, 'EU', 'a source column is never overwritten';
	is $region{1}{shops_region}, 'Europe', 'the clashing field is prefixed with the lookup name';

	my @dup = grep { /duplicate key/ } @warned;
	is scalar(@dup), 1, 'a duplicate key warns once per request';
	like $dup[0] // '', qr/Lookup "shops": 1 duplicate key\(s\) in "shops\.csv"; the first row of each is used/,
		'and says which lookup and file';

	# The table page, the column list and the stats page see the column too.
	$t->get_ok('/view/orders')->status_is(200);
	my $dom = Mojo::DOM->new($t->tx->res->body);
	my @heads = map { $_->all_text =~ s/^\s+|\s+$//gr } @{ $dom->find('#bi-table thead th')->to_array };
	ok((grep { /\bcity\b/ } @heads), 'the table shows the looked-up column')
		or diag explain \@heads;
	like $t->tx->res->body, qr{<td[^>]*>London</td>}, 'with its values';

	$t->get_ok("/stats?$ORDERS")->status_is(200)->content_like(qr/\bshops_region\b/, 'the stats page lists it');
	$t->get_ok("/pivot?$ORDERS&rows=city&m=" . url_escape('amount:sum:total'))->status_is(200)
		->content_like(qr{<td[^>]*>London</td>}, 'a pivot groups by it')
		->content_like(qr/\b40\b/, 'to the London total');
};

subtest 'a filter, a field and a window can read a looked-up column' => sub {
	my @london = _export('f=' . url_escape('city:eq:London'));
	is_deeply [ sort map { $_->{id} } @london ], [ 1, 3 ], 'a filter on it';

	$t->get_ok('/view/orders?f=' . url_escape('city:eq:New York'))->status_is(200);
	like $t->tx->res->body, qr{<td[^>]*>20</td>}, 'on the table page too';
	unlike $t->tx->res->body, qr{<td[^>]*>30</td>}, 'which drops the rows it does not match';

	my @tagged = _export('c=' . url_escape('tag:upper(city)'));
	my ($one) = grep { $_->{id} == 1 } @tagged;
	is $one->{tag}, 'LONDON', 'a calculated field reads it';

	my @ytd = _export('cs=' . url_escape('amount:running_total:rt'), 'by=city', 'order=id');
	my %rt = map { $_->{id} => $_->{rt} } @ytd;
	is_deeply [ @rt{1, 3} ], [ 10, 40 ], 'and a window partitions by it';
};

subtest 'nolk= and lk= control one request' => sub {
	my @rows = _export('nolk=shops');
	ok(!exists $rows[0]{city}, 'nolk= skips a stored lookup');
	$t->get_ok('/view/orders?nolk=shops')->status_is(200)
		->content_like(qr{<input type="hidden" name="nolk" value="shops">}, 'and the panels carry it to the page they open');
	unlike $t->tx->res->body, qr{<td[^>]*>London</td>}, 'whose table goes without the column';

	# A second dataset with no lookup of its own borrows this one by name.
	$data_dir->child('more.csv')->spew("id,shop,amount\n1,NY,5\n");
	$t->get_ok('/export?l=' . url_escape('table:more') . '&format=csv')->status_is(200);
	ok(!exists +(_csv($t->tx->res->body))[0]{city}, 'another dataset does not get it unasked');
	$t->get_ok('/export?l=' . url_escape('table:more') . '&format=csv&lk=shops')->status_is(200);
	is +(_csv($t->tx->res->body))[0]{city}, 'New York', 'lk= applies a lookup stored for another dataset';

	$t->get_ok("/export?$ORDERS&format=csv&lk=nothing")->status_is(400)
		->content_like(qr/Lookup "nothing" is not stored for any dataset/, 'an unknown lk= is a 400');
	$t->get_ok("/export?$ORDERS&format=csv&lk=" . url_escape('a b'))->status_is(400)
		->content_like(qr/is not a valid identifier/, 'as is one that cannot be a name');
};

subtest 'a column the dataset lacks is a 400 that names nolk=' => sub {
	_save(name => 'bykey', file => 'lookups/shops.csv', key => 'code', fields => 'city');
	$t->status_is(200);
	$t->get_ok("/export?$ORDERS&format=csv")->status_is(400)
		->content_like(qr/Lookup "bykey": column "code" is not in this dataset \(nolk=bykey/);
	$t->get_ok("/export?$ORDERS&format=csv&nolk=bykey")->status_is(200, 'which gets the reader past it');
	$t->post_ok('/lookups/delete' => form => { l => $L, name => 'bykey' })->status_is(200)->json_is('/ok', 1);
	$t->get_ok("/lookups/list?$ORDERS")->json_hasnt('/lookups/bykey')->json_has('/lookups/shops');
};

subtest 'fields= and default= shape what is added' => sub {
	_save(name => 'shops', file => 'lookups/shops.csv', key => 'code', col => 'shop',
		fields => 'city', default => 'unknown');
	$t->status_is(200);
	my @rows = _export();
	ok(!exists $rows[0]{shops_region}, 'only the fields named are added');
	my %city = map { $_->{id} => $_->{city} } @rows;
	is $city{4}, 'unknown', 'a key that is not in the file takes the default';
	is $city{1}, 'London', 'one that is keeps its value';
};

subtest 'a lookup applies to a canvas card' => sub {
	my $id = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Lookup canvas',
			datasets => [ { spec => $L, alias => 'left' } ],
			visuals  => [ { kind => 'table', title => 'Cities', encode => { columns => [qw(id city)] } } ],
		}),
	)->status_is(201)->tx->res->json->{id};
	$t->get_ok("/a/$id")->status_is(200)->content_like(qr{<td[^>]*>London</td>}, 'the card shows the column');
};

subtest 'a looked-up group on a SQLite source folds in Perl' => sub {
	plan skip_all => 'DBD::SQLite is not available' unless eval { require DBD::SQLite; 1 };
	my $dbh = DBI->connect('dbi:SQLite:dbname=' . $data_dir->child('ledger.sqlite'),
		'', '', { RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE ledger (id INTEGER PRIMARY KEY, shop TEXT, amount REAL)');
	$dbh->do('INSERT INTO ledger VALUES (?,?,?)', undef, @$_) for
		[ 1, 'LDN', 10 ], [ 2, 'NY', 20 ], [ 3, 'LDN', 30 ];
	$dbh->disconnect;

	my $ls = 'table:ledger';
	$t->post_ok('/lookups/save' => form => { l => $ls, name => 'shops', file => 'lookups/shops.csv',
		key => 'code', col => 'shop', fields => 'city' })->status_is(200);

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
	my $q = '/pivot?l=' . url_escape($ls) . '&rows=city&m=' . url_escape('amount:sum:total');
	my $page = $cells->($q);
	is $pushed, 0, 'a looked-up column as the group never reaches aggregate()';
	is_deeply $page, [ 'London', 40, 'NewYork', 20 ], 'and the totals are right';
	local $ENV{BI_FORCE_PERL_AGG} = 1;
	is_deeply $cells->($q), $page, 'the same with the fold forced';

	$t->get_ok('/view/ledger')->status_is(200)->content_like(qr{<td[^>]*>New York</td>},
		'the locked rows of a SQL source take the column');
};

subtest 'delete without name= clears the dataset' => sub {
	$t->post_ok('/lookups/delete' => form => { l => $L })->status_is(200);
	$t->get_ok("/lookups/list?$ORDERS")->json_is('/lookups', {});
	ok(!exists +(_export())[0]{city}, 'and the column is gone');
};

done_testing;
