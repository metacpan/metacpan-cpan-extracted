use strict;
use warnings;
use Test::Most;
use Test::Mojo;
use File::Temp qw(tempdir);
use Mojo::File qw(path);
use Mojo::Util qw(url_escape);

# Columns the reader deleted in the table are not exported: the Export panel
# sends the columns still shown as repeated xcol=, in the table's order.

my $data = tempdir(CLEANUP => 1);
my $out  = tempdir(CLEANUP => 1);
path($data, 'a.csv')->spurt("id,name,secret\n1,Ann,x\n2,Bob,y\n");

my $t = Test::Mojo->new('Database::BI');
$t->app->config->{data_dir}  = $data;
$t->app->config->{export_dirs} = [ $out ];
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

my $l = 'l=' . url_escape("path:$data/a.csv");

$t->get_ok("/export?$l&format=csv")->content_like(qr/secret/, 'all columns by default');
$t->get_ok("/export?$l&format=csv&xcol=name&xcol=id")
  ->content_like(qr/\A"?name"?,"?id"?\r?\n/, 'kept columns, in the given order')
  ->content_unlike(qr/secret|\bx\b/, 'deleted column is gone');
$t->get_ok("/export?$l&format=json&xcol=id")
  ->json_is('/0' => { id => 1 }, 'JSON rows hold only the kept column');
$t->get_ok("/export?$l&format=csv&xcol=nosuch")
  ->content_like(qr/secret/, 'no known column named: everything kept');

$t->get_ok("/export?$l&format=json&xcol=name&xcol=secret&xcol=id")
  ->content_like(qr/\A\[\{"name":"Ann","secret":"x","id":"?1"?\},/, 'JSON keys follow the column order')
  ->header_like('Content-Type' => qr{application/json}, 'still JSON');

# The Export panel saves through POST /export, which has its own call site.
$t->post_ok('/export' => form => {
	l => "path:$data/a.csv", dir => "$out", filename => 'kept.csv', xcol => [ 'name', 'id' ],
})->status_is(200)->json_has('/saved');
my $saved = path($out, 'kept.csv')->slurp;
like($saved, qr/\A"?name"?,"?id"?\r?\n/, 'POST: kept columns, in order');
unlike($saved, qr/secret/, 'POST: deleted column is not written');

$t->post_ok('/export' => form => {
	l => "path:$data/a.csv", dir => "$out", filename => 'order.json', xcol => [ 'secret', 'id' ],
})->status_is(200);
like(path($out, 'order.json')->slurp, qr/\A\[\{"secret":"x","id":"?1"?\}/, 'POST: JSON keys in order');

$t->post_ok('/export' => form => {
	l => "path:$data/a.csv", dir => "$out", filename => 'kept.sql', xcol => [ 'id' ],
})->status_is(200);
ok(-s path($out, 'kept.sql'), 'POST: SQLite export is written');

# Non-ASCII names and values survive the hand-built JSON.
my $uni = tempdir(CLEANUP => 1);
path($uni, 'u.csv')->spurt("id,caf\xc3\xa9\n1,na\xc3\xafve\n");
$t->get_ok('/export?l=' . url_escape("path:$uni/u.csv") . '&format=json&xcol=caf%C3%A9')
  ->json_is('/0' => { "caf\x{e9}" => "na\x{ef}ve" }, 'non-ASCII key and value');

# SQL-backed rows are locked hashes: selecting columns must not write to them.
SKIP: {
	eval { require DBI; require DBD::SQLite; 1 } or skip 'DBD::SQLite not installed', 3;
	my $db = tempdir(CLEANUP => 1);
	my $dbh = DBI->connect("dbi:SQLite:dbname=$db/shop.sql", '', '', { RaiseError => 1 });
	$dbh->do('CREATE TABLE shop (id INTEGER PRIMARY KEY, name TEXT, secret TEXT)');
	$dbh->do(q{INSERT INTO shop VALUES (1, 'Ann', 'x'), (2, 'Bob', 'y')});
	$dbh->disconnect;
	my $q = 'l=' . url_escape("path:$db/shop.sql");
	$t->get_ok("/export?$q&format=csv&xcol=name")
	  ->status_is(200)
	  ->content_unlike(qr/secret|\bid\b/, 'SQLite source: only the kept column');
}

done_testing;
