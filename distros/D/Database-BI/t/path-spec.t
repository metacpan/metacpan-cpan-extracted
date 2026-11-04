use strict;
use warnings;

use Test::More;
use Test::Mojo;
use Mojo::DOM  ();
use Mojo::File ();
use File::Temp ();
use Mojo::JSON ();
use DBI ();
use Mojo::Util qw(url_escape);

use Database::BI::Controller::Dashboard ();

use lib 't/lib';
use BI::Test::Command qw(run_command);

# ---------------------------------------------------------------------------
# A path: spec has one spelling: the realpath of its file, which is how /open
# names it.  Definitions saved, and extracts built, under a path reached
# through a symlink must be the ones the file's page reads.  macOS found this:
# its tempdir is under /var, a symlink to /private/var, so a test that saved
# under the tempdir's path saw nothing on /open.  Here the symlink is made on
# purpose, so the same failure shows on every platform that has symlinks.
#
#   prove -l t/path-spec.t
# ---------------------------------------------------------------------------

my $root = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1));
my $real = $root->child('real')->make_path;
my $link = $root->child('link');
plan skip_all => 'symlinks are not available here'
	unless eval { symlink($real->to_string, $link->to_string) } && -d $link->to_string;

my $data_dir  = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1));
my $model_dir = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1));
$real->child('sales.csv')->spew("id,region,email,amount\n1,North,ann\@x.com,10\n2,South,bob\@y.org,5\n");

my $via_link  = $link->child('sales.csv')->to_string;
my $canonical = Mojo::File->new($via_link)->realpath->to_string;
isnt($via_link, $canonical, 'the file has two spellings');

my $t = Test::Mojo->new('Database::BI', {
	data_dir  => $data_dir->to_string,
	model_dir => $model_dir->to_string,
});
$t->app->log->level('fatal');

sub _dom   { Mojo::DOM->new($t->tx->res->body) }
sub _heads { [ _dom()->find('#bi-table thead th')->map('all_text')->each ] }
sub _has   { my ($col) = @_; return scalar grep { $_ eq $col } @{ _heads() } }
sub _open  { $t->get_ok('/open?path=' . url_escape(shift // $via_link))->status_is(200) }

subtest 'canonical_spec' => sub {
	my $cs = \&Database::BI::Controller::Dashboard::canonical_spec;
	is($cs->("path:$via_link"), "path:$canonical", 'a symlinked path is resolved');
	is($cs->("path:$canonical"), "path:$canonical", 'a resolved one is left alone');
	for my $spec ('table:sales', 'url:https://example.com/x.csv', 'path:/../host/dir/x.csv',
		'path:' . $link->child('missing.csv'), "path:$via_link\nx", '') {
		is($cs->($spec), $spec, 'unchanged: ' . ($spec =~ s/\n/\\n/r));
	}
	is($cs->(undef), undef, 'undef stays undef');
};

subtest 'a saved group, field, lookup and extraction reach /open' => sub {
	my $l = "path:$via_link";
	$t->post_ok('/groups/save' => form => { l => $l, col => 'region', group => 'Northern', values => 'North' })
		->status_is(200);
	$t->post_ok('/calc/save' => form => { l => $l, name => 'dbl', expr => 'amount * 2' })->status_is(200);
	$t->post_ok('/extract/save' => form => { l => $l, name => 'em', col => 'email', pattern => '@(?<domain>[\w.-]+)' })
		->status_is(200);

	for my $path ($via_link, $canonical) {
		_open($path);
		ok(_has($_), "/open of $path shows $_") for qw(region_group dbl domain);
	}

	$t->get_ok('/groups/list?l=' . url_escape("path:$canonical"))->status_is(200)
		->json_has('/groups/region/Northern', 'the store lists it under the resolved path');
	$t->get_ok('/groups/list?l=' . url_escape($l))->status_is(200)
		->json_has('/groups/region/Northern', 'and the link finds it too');

	$t->post_ok('/groups/delete' => form => { l => $l })->status_is(200);
	$t->post_ok('/calc/delete' => form => { l => $l, name => 'dbl' })->status_is(200);
	$t->post_ok('/extract/delete' => form => { l => $l })->status_is(200);
	_open();
	ok(!_has($_), "deleted through the link, $_ is gone") for qw(region_group dbl domain);
};

subtest 'a chart reached through the link uses the saved group' => sub {
	$t->post_ok('/groups/save' => form => {
		l => "path:$canonical", col => 'region', group => 'Northern', values => 'North',
	})->status_is(200);
	$t->get_ok('/bar?l=' . url_escape("path:$via_link") . '&cat=region_group&val=amount')
		->status_is(200)->content_like(qr/Northern/);
};

subtest 'a canvas dataset named through the link uses it too' => sub {
	my $id = $t->post_ok('/api/analyses' => json => {
		name     => 'Linked',
		datasets => [ { spec => "path:$via_link", alias => 'left' } ],
		visuals  => [ { kind => 'bar', encode => { cat => 'region_group', val => 'amount' }, title => 'G' } ],
	})->status_is(201)->tx->res->json->{id};
	$t->get_ok("/a/$id")->status_is(200)->content_like(qr/Northern/);
	$t->post_ok('/groups/delete' => form => { l => "path:$canonical" })->status_is(200);
};

subtest 'the request keeps the spelling the reader gave' => sub {
	my $l = "path:$via_link";
	$t->get_ok('/combine?l=' . url_escape($l) . '&c=' . url_escape($l))->status_is(200);
	my $form = _dom()->at('form#graph-form');
	ok($form, 'the graph form is on the page') or return;
	my %has = map { ($_->{name} // '') => $_->{value} } $form->find('input[type=hidden]')->each;
	is($has{l}, $l, 'l= as given');
	is($has{c}, $l, 'c= as given');

	plan skip_all => 'DBD::SQLite is not available' unless eval { require DBD::SQLite; 1 };
	my $lite = $real->child('lite.sqlite');
	my $dbh = DBI->connect("dbi:SQLite:dbname=$lite", '', '', { RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE lite (id INTEGER)');
	$dbh->disconnect;
	require Mojo::Transaction::HTTP;
	my $tx = Mojo::Transaction::HTTP->new;
	my $c  = Database::BI::Controller::Dashboard->new(app => $t->app, tx => $tx);
	my $spec = 'path:' . $link->child('lite.sqlite');
	my $ok = eval { Database::BI::Controller::Dashboard::accelerate($c, $spec); 1 };
	ok(!$ok, 'a SQLite file is refused');
	like($@, qr/\ACannot accelerate "\Q$spec\E"/, 'and the message names the spec as written');
	$lite->remove;
};

subtest 'an entry stored under the symlinked spelling is still read' => sub {
	my $store = $model_dir->child('models.json');
	my $models = Mojo::JSON::decode_json($store->slurp);
	$models->{fields}{"path:$via_link"} = { tripled => 'amount * 3' };
	$store->spew(Mojo::JSON::encode_json($models));
	_open();
	ok(_has('tripled'), '/open shows it');
	$t->post_ok('/calc/delete' => form => { l => "path:$canonical", name => 'tripled' })->status_is(200);
	_open();
	ok(!_has('tripled'), 'and deleting it under the resolved spelling removes it');
	ok(!exists Mojo::JSON::decode_json($store->slurp)->{fields}{"path:$via_link"}, 'the old key is gone from the file');
};

subtest 'bi-extract --spec through the link accelerates /open' => sub {
	plan skip_all => 'DBD::SQLite is not available' unless eval { require DBD::SQLite; 1 };
	my @dirs = ('--data-dir', $data_dir->to_string, '--model-dir', $model_dir->to_string);
	my $cli = sub {
		my ($exit, $stdout, $stderr, $timed_out) = run_command([ $^X, '-Ilib', 'script/bi-extract', @dirs, @_ ]);
		if ($timed_out) {
			fail("bi-extract @_ finished");
			diag("stdout:\n$stdout\nstderr:\n$stderr");
		}
		return ($exit, $stdout);
	};
	my ($code) = $cli->('--spec', "path:$via_link");
	is($code, 0, 'built');
	_open();
	my $note = _dom()->at('#accel-note');
	is($note && $note->attr('data-state'), 'fresh', '/open reads it from the extract');

	($code, my $out) = $cli->('--list');
	like($out, qr/\Q$canonical\E/, 'listed under the resolved path');

	($code, $out) = $cli->('--remove', '--spec', "path:$via_link");
	like($out, qr/no longer accelerated/, 'removed through the link');
	_open();
	ok(!_dom()->at('#accel-note'), 'and /open says nothing');
};

done_testing();
