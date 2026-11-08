#!/usr/bin/env perl

# A .json file on disk is a table, as a .csv is: dropped on a page, opened
# from the browser, or named in data_dir.  Database::Abstraction reads a flat
# copy that DataSource writes, so these check what that copy holds (the
# shapes that are tables, the column order, nested values) and the routes
# that reach it (upload, /open, /tables, a chart).
#
#   prove -l t/json.t

use strict;
use warnings;

use Test::Most;
use Test::Mojo;
use File::Spec;
use File::Temp qw(tempdir);
use Mojo::File;
use Mojo::Util qw(url_escape);

my $t = Test::Mojo->new('Database::BI');
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

require Database::BI::Model::DataSource;
my $DS = 'Database::BI::Model::DataSource';

# json_file($name, $text) -> ($dir, $stem, $path): each in a folder of its own,
# since two files with one stem are one table.
sub json_file {
	my ($name, $text) = @_;
	my $dir  = tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($dir, $name);
	Mojo::File->new($path)->spew($text);
	(my $stem = $name) =~ s/\.[^.]+\z//;
	return ($dir, $stem, $path);
}

sub open_json {
	my ($text, %args) = @_;
	my ($dir, $stem) = json_file('rows.json', $text);
	return $DS->new(directory => $dir, table => $stem, %args);
}

subtest 'a list of objects: each a row, the columns in the order of the file' => sub {
	my $ds   = open_json('[{"zeta": 1, "alpha": "x", "mid": 2.5}, {"alpha": "y", "zeta": 2, "extra": "e"}]');
	my $rows = $ds->fetch_all;
	is scalar @{$rows}, 2, 'two rows';
	is_deeply $ds->columns, [qw(zeta alpha mid extra)], 'columns as the file first names them, not sorted';
	is $rows->[1]{extra}, 'e', 'a key only a later row has is a column';
	ok !defined $rows->[0]{extra}, 'and empty where a row lacks it';
	is $ds->sqlite_tables, undef, 'a list of rows is one table';
};

subtest 'a cell holding more than a value' => sub {
	my $rows = open_json('[{"id": "a", "tags": ["x", "y"], "where": {"lat": 1, "lon": 2}, "ok": true, "no": false, "gone": null}]')->fetch_all;
	is $rows->[0]{tags},  '["x","y"]',           'a list is its JSON text';
	is $rows->[0]{where}, '{"lat":1,"lon":2}',   'an object is its JSON text';
	is $rows->[0]{ok},    'true',                'true is the word';
	is $rows->[0]{no},    'false',               'false is the word';
	ok !defined $rows->[0]{gone},                'null is an empty cell';
	ok !(grep { ref } values %{ $rows->[0] }),   'no cell is a reference';
};

subtest 'nested objects do not add columns' => sub {
	my $ds = open_json('[{"a": {"inner": 1, "b": 2}, "c": 3}]');
	is_deeply $ds->columns, [qw(a c)], 'keys inside a cell are not columns';
};

subtest 'keys with quotes, escapes and letters outside ASCII' => sub {
	my $ds = open_json(qq{[{"say \\"hi\\"": 1, "caf\\u00e9": 2, "back\\\\slash": 3, "\xc4\x8dlen": 4}]});
	is_deeply $ds->columns, ["say \"hi\"", "caf\x{e9}", 'back\\slash', "\x{10d}len"], 'each key decoded, in order';
	is $ds->fetch_all->[0]{"caf\x{e9}"}, 2, 'and its value read';
};

subtest 'a value outside ASCII survives the copy' => sub {
	my $rows = open_json(qq{[{"city": "Z\xc3\xbcrich", "name": "\xc4\x8cesk\xc3\xbd"}]})->fetch_all;
	is $rows->[0]{city}, "Z\x{fc}rich", 'a Latin-1 letter';
	is $rows->[0]{name}, "\x{10c}esk\x{fd}", 'and one past U+00FF';
};

subtest 'an object holding one list: the list is the table' => sub {
	my $ds = open_json('{"generated": "2026-11-06", "count": 2, "findings": [{"sev": "low", "title": "a"}, {"sev": "high", "title": "b"}]}');
	is scalar @{ $ds->fetch_all }, 2, 'the rows of the list';
	is_deeply $ds->columns, [qw(sev title)], 'its columns';
	is_deeply $ds->sqlite_tables, ['findings'], 'named as the one table';
};

subtest 'an object holding several lists: each a table' => sub {
	my $text = '{"tool": "scan", "hosts": [{"host": "h1", "ports": [80]}], "summary": {"low": 1}, "findings": [{"title": "t1"}, {"title": "t2"}], "empty": []}';
	my $ds = open_json($text);
	is_deeply $ds->sqlite_tables, [qw(hosts findings)], 'the lists with rows, in the order of the file';
	is $ds->fetch_all->[0]{host}, 'h1', 'the first is read by default';
	my $second = open_json($text, internal_table => 'findings');
	is scalar @{ $second->fetch_all }, 2, 'internal_table reads another';
	is_deeply $second->columns, ['title'], 'with its own columns';
	throws_ok { open_json($text, internal_table => 'summary') } qr/no list of objects called "summary"/,
		'an object of totals is not a table';
	throws_ok { open_json($text, internal_table => 'empty') } qr/no list of objects called "empty"/,
		'nor is an empty list, when another has rows';
};

subtest 'an empty list counts when no list has rows' => sub {
	my $ds = open_json('{"items": [], "count": 0}');
	is_deeply $ds->fetch_all, [], 'no rows';
	is_deeply $ds->sqlite_tables, ['items'], 'from the one list';
};

subtest 'an object of objects: each key a row' => sub {
	my $ds = open_json('{"k2": {"name": "B"}, "k1": {"name": "A"}}');
	is_deeply $ds->columns, [qw(id name)], 'the key in a column id, first';
	is_deeply [ map { $_->{id} } @{ $ds->fetch_all } ], [qw(k2 k1)], 'the rows in the order of the file';

	my $taken = open_json('{"k1": {"id": 7, "name": "A"}}');
	is_deeply $taken->columns, [qw(key id name)], 'key when the rows have an id';
	is $taken->fetch_all->[0]{id}, 7, 'and their id kept';
};

subtest 'empty files are empty tables' => sub {
	for my $text ('', "  \n", '[]') {
		my $ds = open_json($text);
		my $name = length $text ? "'" . ($text =~ s/\n/\\n/gr) . "'" : 'zero bytes';
		is_deeply $ds->fetch_all, [], "no rows for $name";
	}
};

subtest 'what is not a table' => sub {
	throws_ok { open_json('[{"a": 1},') }   qr/is not valid JSON/,     'broken JSON';
	throws_ok { open_json('[1, 2, 3]') }    qr/holds no table/,         'a list of numbers';
	throws_ok { open_json('[{"a": 1}, 2]') } qr/holds no table/,        'a list with a number in it';
	throws_ok { open_json('"text"') }       qr/holds no table/,         'a string';
	throws_ok { open_json('{"a": 1, "b": [1]}') } qr/holds no table/,   'an object of values';
	unlike $@, qr/ at \S+ line \d+.*JSON/s, 'the reason has no Perl location in it';
};

subtest 'a file of the same name in another format is the one read' => sub {
	my ($dir) = json_file('both.json', '[{"from": "json"}]');
	Mojo::File->new($dir, 'both.csv')->spew("from\ncsv\n");
	is $DS->new(directory => $dir, table => 'both')->fetch_all->[0]{from}, 'csv', 'the CSV, as Database::Abstraction picks';
};

subtest 'a file name that is not an identifier' => sub {
	my ($dir) = json_file('web scan-1.json', '[{"a": 1}]');
	my $ds = $DS->new(directory => $dir, table => 'web scan-1');
	is $ds->fetch_all->[0]{a}, 1, 'read through the safe-name link';
};

subtest 'the flat copy is gone with the source' => sub {
	my $ds  = open_json('[{"a": 1}]');
	my $tmp = "$ds->{_json_tmpdir}";
	ok -d $tmp, 'a copy while the source is open';
	undef $ds;
	ok !-e $tmp, 'none after';
};

subtest 'json_lists' => sub {
	my (undef, undef, $path) = json_file('lists.json', '{"b": [{"y": 1, "x": 2}], "a": [{"z": 1}], "n": 3}');
	is_deeply $DS->json_lists($path),
		[ { name => 'b', columns => [qw(y x)] }, { name => 'a', columns => ['z'] } ],
		'each list, in the order of the file';
	my (undef, undef, $plain) = json_file('plain.json', '[{"a": 1}]');
	is_deeply $DS->json_lists($plain), [], 'none in a list of rows';
	my (undef, undef, $broken) = json_file('broken.json', '{');
	throws_ok { $DS->json_lists($broken) } qr/is not valid JSON/, 'broken JSON';
	$@ = 'before';
	$DS->json_lists($plain);
	is $@, 'before', "the caller's \$@ survives";
};

# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

my $SCAN = <<'JSON';
{
   "tool" : "scan",
   "findings" : [
      { "severity" : "low",  "title" : "Port 3000 open", "host" : "localhost",    "score" : 2 },
      { "severity" : "high", "title" : "Old TLS",        "host" : "example.test", "score" : 7 }
   ],
   "hosts" : [
      { "host" : "localhost", "open_ports" : [3000, 8080] }
   ],
   "summary" : { "low" : 1, "high" : 1 }
}
JSON

subtest 'dropping a file: one list opens as a table' => sub {
	my (undef, undef, $path) = json_file('one.json', '[{"name": "Ada", "role": "eng"}, {"name": "Bo", "role": "ops"}]');
	$t->post_ok('/upload', form => { file => { file => $path } })->status_is(200);
	my $url = $t->tx->res->json->{url};
	like $url, qr{\A/open\?path=.*one\.json\z}, 'the upload answers with the page to open';
	$t->get_ok($url)->status_is(200)
	  ->content_like(qr{<td[^>]*>Ada</td>}, 'its rows')
	  ->content_like(qr{<th[^>]*>.*?name.*?</th>.*?<th[^>]*>.*?role}s, 'its columns in order');
};

subtest 'dropping a file of several lists goes to its tables' => sub {
	my (undef, undef, $path) = json_file('scan.json', $SCAN);
	$t->post_ok('/upload', form => { file => { file => $path } })->status_is(200);
	my $url = $t->tx->res->json->{url};
	$t->get_ok($url)->status_is(302);
	my $tables = $t->tx->res->headers->location;
	like $tables, qr{\A/tables\?l=path%3A}, 'to /tables';

	$t->get_ok($tables)->status_is(200)->content_like(qr/findings/)->content_like(qr/hosts/);
	my @cards = $t->tx->res->dom->find('a[href*="it="]')->map(attr => 'href')->each;
	is scalar @cards, 2, 'a card for each list';
	like $t->tx->res->body, qr/open_ports/, 'with its columns';
	unlike $t->tx->res->body, qr/>summary</, 'an object of totals is no card';

	my ($hosts) = grep { /it=hosts/ } @cards;
	$t->get_ok($hosts)->status_is(200)
	  ->content_like(qr{<td[^>]*>localhost</td>}, 'the hosts list opens')
	  ->content_like(qr{\[3000,8080\]}, 'a list in a cell as its JSON text');
	$t->get_ok("$url&it=nothing")->status_is(200)->content_like(qr/no list of objects called/, 'a list it does not have');
};

subtest 'path:<file>#<table> names one table of a file' => sub {
	my $split = \&Database::BI::Model::DataSource::split_path;
	is_deeply [ $split->('/no/such/scan.json#hosts') ], ['/no/such/scan.json', 'hosts'], 'the table after a #';
	is_deeply [ $split->('/no/such/scan.json') ], ['/no/such/scan.json', undef], 'none without one';
	my ($dir) = json_file('odd#name.json', '[{"a": 1}]');
	my $odd = File::Spec->catfile($dir, 'odd#name.json');
	is_deeply [ $split->($odd) ], [$odd, undef], 'a file whose name has a # in it is that file';
	is_deeply [ $split->(undef) ], ['', undef], 'undef';
	is_deeply [ $split->('/../host/dir/scan.json#hosts') ], ['/../host/dir/scan.json', 'hosts'], 'a remote path';

	my (undef, undef, $path) = json_file('scan.json', $SCAN);
	my $hosts = "path:$path#hosts";
	# /open names its file by the realpath (macOS's tempdir is under /var, a
	# link to /private/var), and keeps the table after it.
	my $opened = 'path:' . Mojo::File->new($path)->realpath . '#hosts';
	$t->get_ok('/open?path=' . url_escape($path) . '&it=hosts')->status_is(200)
	  ->element_exists(qq{input[name="l"][value="$opened"]}, 'the page passes the table on in l=');
	$t->get_ok('/api/columns?spec=' . url_escape($hosts))->status_is(200)
	  ->json_is('/columns/0' => 'host', 'the columns of that table')
	  ->json_hasnt('/columns/2', 'and not the first list\'s');
	$t->get_ok('/bar?cat=host&val=host&l=' . url_escape($hosts))->status_is(200);
	unlike $t->tx->res->body, qr/example\.test/, 'a chart of it reads it, not the first list';
	$t->get_ok('/open?path=' . url_escape("$path#hosts"))->status_is(200)
	  ->content_like(qr{\[3000,8080\]}, '/open?path= takes the same form');
	$t->get_ok('/tables?l=' . url_escape($hosts))->status_is(200)->content_like(qr/findings/, '/tables lists every table still');
	$t->get_ok('/open?path=' . url_escape($odd))->status_is(200)->content_like(qr{<td[^>]*>1</td>}, 'and opens a file with a # in its name');
};

subtest 'path:<file>#<table> for a SQLite file outside data_dir' => sub {
	plan skip_all => 'DBD::SQLite is not available' unless eval { require DBI; DBI->install_driver('SQLite'); 1 };
	my $dir = tempdir(CLEANUP => 1);
	my $db  = File::Spec->catfile($dir, 'shop.sqlite');
	my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE alpha (sku TEXT, qty INTEGER)');
	$dbh->do(q{INSERT INTO alpha VALUES ('a1', 1)});
	$dbh->do('CREATE TABLE beta (label TEXT, price INTEGER)');
	$dbh->do(q{INSERT INTO beta VALUES ('b-only', 9)});
	$dbh->disconnect;
	my $beta = "path:$db#beta";
	my $opened = 'path:' . Mojo::File->new($db)->realpath . '#beta';
	$t->get_ok('/open?path=' . url_escape($db) . '&it=beta')->status_is(200)
	  ->element_exists(qq{input[name="l"][value="$opened"]}, 'the second table is kept in l=');
	$t->get_ok('/bar?cat=label&val=price&l=' . url_escape($beta))->status_is(200)->content_like(qr/b-only/, 'and charted');
	$t->get_ok('/export?format=csv&l=' . url_escape($beta))->status_is(200)->content_like(qr/b-only/, 'and exported');
};

subtest 'a chart of a JSON file' => sub {
	my (undef, undef, $path) = json_file('scan.json', $SCAN);
	$t->get_ok('/bar?cat=severity&val=score&l=' . url_escape("path:$path"))->status_is(200)
	  ->content_like(qr/high/)->content_like(qr/low/);
};

subtest 'a JSON file in data_dir' => sub {
	my $data = tempdir(CLEANUP => 1);
	Mojo::File->new($data, 'team.json')->spew('[{"name": "Ada"}]');
	Mojo::File->new($data, 'scan.json')->spew($SCAN);
	# open_table reads data_dir when the app starts, so this one has its own.
	my $t = Test::Mojo->new('Database::BI', { data_dir => $data, model_dir => tempdir(CLEANUP => 1) });
	$t->get_ok('/')->status_is(200)->content_like(qr/team/, 'listed on the home page');
	$t->get_ok('/view/team')->status_is(200)->content_like(qr{<td[^>]*>Ada</td>}, '/view reads it');
	$t->get_ok('/view/scan')->status_is(302)->header_like(Location => qr{\A/tables\?l=table%3Ascan\z}, 'several lists go to /tables');
	$t->get_ok('/tables?l=table:scan')->status_is(200)->content_like(qr/findings/);
};

subtest 'Browse lists JSON files' => sub {
	my ($dir) = json_file('listed.json', '[{"a": 1}]');
	$t->get_ok('/browse?path=' . url_escape($dir))->status_is(200)->content_like(qr/listed\.json/);
};

done_testing();
