use strict;
use warnings;

# A SQLite file can hold tables that Database::Abstraction refuses to read,
# because their names are not safe identifiers: a CHI cache has chi_CGI::Info.
#
#   * such a table must not stop the rest of the file being opened;
#   * the table list says which ones cannot be opened, why, and how to rename them;
#   * when one is asked for by name, or nothing else is left, the error says
#     what is wrong and what to do, and does not show source file positions.
#
#   prove -l t/sqlite-table-names.t

use Test::More;
use Test::Mojo;
use Mojo::DOM;
use Mojo::File;
use Mojo::Util qw(url_escape);
use File::Temp ();

plan skip_all => 'DBD::SQLite not available' unless eval { require DBD::SQLite; 1 };

my $dir = File::Temp::tempdir(CLEANUP => 1);

sub make_db {
	my ($file, @tables) = @_;
	my $path = "$dir/$file";
	my $dbh  = DBI->connect("dbi:SQLite:dbname=$path", q{}, q{}, { RaiseError => 1, AutoCommit => 1 });
	for my $table (@tables) {
		(my $quoted = $table) =~ s/"/""/g;
		$dbh->do(qq{CREATE TABLE "$quoted" (name TEXT, amount INTEGER)});
		$dbh->do(qq{INSERT INTO "$quoted" VALUES ('$file', 7)});
	}
	$dbh->disconnect;
	return $path;
}

my $mixed = make_db('mixed.sqlite', 'chi_CGI::Info', 'chi_page', 'chi_twitter');
my $one   = make_db('one.sqlite', 'bad name', 'good');
my $none  = make_db('none.sqlite', 'chi_CGI::Info', '2024-data');

my $t = Test::Mojo->new('Database::BI');
$t->app->config->{model_dir} = File::Temp::tempdir(CLEANUP => 1);

subtest 'a file whose first table has an unusable name still opens' => sub {
	my $url = '/open?path=' . url_escape($mixed);
	$t->get_ok($url)->status_is(302, 'several tables: to the table list');
	my $list = $t->tx->res->headers->location;
	like($list, qr{\A/tables\?l=}, 'and the list is where it goes');

	my $dom = Mojo::DOM->new($t->get_ok($list)->status_is(200)->tx->res->body);
	my @links = $dom->find('a.table-card .table-card-name')->map('text')->each;
	is(scalar(@links), 2, 'the two usable tables are links');
	ok((grep { /chi_page/ } @links) && (grep { /chi_twitter/ } @links), "chi_page and chi_twitter can be opened");

	my $bad = $dom->at('.table-card-unusable');
	ok($bad, 'the other has a card of its own');
	ok(!$dom->at('a.table-card-unusable'), 'which is not a link');
	like($bad->text . $bad->all_text, qr/chi_CGI::Info/, 'it names the table');
	like($bad->all_text, qr/letters, digits and underscores/, 'says what is wrong');
	like($bad->at('code')->text, qr/ALTER TABLE "chi_CGI::Info" RENAME TO chi_CGI__Info;/, 'and how to rename it');
	like($bad->all_text, qr/copy of the file/, 'in a copy, not the original');
};

subtest 'the chosen table is the first one that can be opened' => sub {
	require Database::BI::Model::DataSource;
	my $source = Database::BI::Model::DataSource->new(directory => $dir, table => 'mixed');
	my $rows   = $source->fetch_all;
	is(scalar(@{$rows}), 1, 'rows are read from a usable table');
	is($rows->[0]{name}, 'mixed.sqlite', 'which is the expected data');
	is_deeply($source->sqlite_tables, [ 'chi_CGI::Info', 'chi_page', 'chi_twitter' ],
		'and sqlite_tables still lists all of them');
};

subtest 'asking for an unusable table by name says what to do' => sub {
	my $body = $t->get_ok('/open?path=' . url_escape($mixed) . '&it=' . url_escape('chi_CGI::Info'))
		->status_is(200)->tx->res->body;
	my $error = Mojo::DOM->new($body)->at('p.error')->text;
	like($error, qr/The table "chi_CGI::Info" in "mixed" cannot be opened/, 'names the table and the file');
	like($error, qr/letters, digits and underscores/, 'says what is wrong');
	like($error, qr/Open another table in the file instead: chi_page, chi_twitter\./, 'names what can be opened');
	like($error, qr/ALTER TABLE "chi_CGI::Info" RENAME TO chi_CGI__Info;/, 'and how to rename it');
	unlike($error, qr/ line \d+/, 'no source positions');
	unlike($error, qr/\.pm\b/, 'no source files');
	unlike($error, qr/DataSource|Database::BI/, 'no internal names');
	ok(!Mojo::DOM->new($body)->at('p.hint'), 'and no generic hint beside it');
};

subtest 'a file with no usable table says so' => sub {
	my $body = $t->get_ok('/open?path=' . url_escape($none))->status_is(200)->tx->res->body;
	my $error = Mojo::DOM->new($body)->at('p.error')->text;
	like($error, qr/\ACould not open "none\.sqlite": No table in "none" can be opened/, 'says what failed');
	like($error, qr/2024-data, chi_CGI::Info/, 'lists the tables');
	like($error, qr/ALTER TABLE "2024-data" RENAME TO _2024_data;/, 'and a digit-leading name is made safe');
	unlike($error, qr/ line \d+/, 'no source positions');
};

subtest 'one usable table among others still goes to the list' => sub {
	$t->get_ok('/open?path=' . url_escape($one))->status_is(302);
	my $dom = Mojo::DOM->new($t->get_ok($t->tx->res->headers->location)->tx->res->body);
	is($dom->find('a.table-card')->size, 1, 'the good table is a link');
	is($dom->find('.table-card-unusable')->size, 1, 'and the other explains itself');
};

subtest 'a usable table opens as before' => sub {
	$t->get_ok('/open?path=' . url_escape($mixed) . '&it=chi_page')
		->status_is(200)->content_like(qr/mixed\.sqlite/, 'its rows are shown');
};

subtest 'other SQLite errors keep the hint, and lose the source positions' => sub {
	my $path = "$dir/empty_db.sqlite";
	my $dbh  = DBI->connect("dbi:SQLite:dbname=$path", q{}, q{}, { RaiseError => 1, AutoCommit => 1 });
	$dbh->do('CREATE TABLE gone (a TEXT)');
	$dbh->do('DROP TABLE gone');
	$dbh->disconnect;
	my $dom = Mojo::DOM->new($t->get_ok('/open?path=' . url_escape($path))->tx->res->body);
	like($dom->at('p.error')->text, qr/contains no user-defined tables/, 'the error is reported');
	unlike($dom->at('p.error')->text, qr/ line \d+/, 'without source positions');
	like($dom->at('p.hint')->text, qr/at least one user-defined table/, 'a .sqlite file gets the hint');
};

done_testing();
