use strict;
use warnings;

use Test::More;
use Test::Mojo;
use Mojo::DOM  ();
use Mojo::File ();
use File::Temp ();
use Mojo::Util qw(url_escape);
use DBI ();

use Database::BI::Controller::Dashboard ();

use lib 't/lib';
use BI::Test::Command qw(run_command);

# ---------------------------------------------------------------------------
# Accelerated views -- Phase 7 item 7.5.
#
# script/bi-extract marks a dataset accelerated and builds its extract, a
# SQLite copy under <model_dir>/extracts/, through Database::BI::Extract.  The
# pages read the extract while its fingerprint (spec, mtime, size) matches the
# file, and the file itself, saying so, once it does not.  These tests follow
# BI-Phase-7.md section 8: the same answers from the extract as from the file,
# never stale numbers, a deleted extracts/ directory costing nothing, and
# nothing written under data_dir.
#
#   prove -l t/extract-cli.t
# ---------------------------------------------------------------------------

plan skip_all => 'DBD::SQLite is not available' unless eval { require DBD::SQLite; 1 };

my $data_dir  = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1));
my $model_dir = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1));

my $SALES = join("\n",
	'id,region,amount,First Name',
	'1,North,10,Ann',
	'2,South,20,Bob',
	'3,North,(5),Cy',
	'4,East,,Di',
) . "\n";
$data_dir->child('sales.csv')->spew($SALES);
my $db = $data_dir->child('store.sqlite');
{
	my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE store (id INTEGER, v TEXT)');
	$dbh->disconnect;
}

# _cli(@args) -> ($exit, $stdout, $stderr)
# A run past its deadline fails here, with what it had written, rather than
# hanging the file (as open3's pipes did on Windows).
sub _cli {
	my ($exit, $stdout, $stderr, $timed_out) = run_command([ $^X, '-Ilib', 'script/bi-extract', @_ ]);
	if ($timed_out) {
		fail("bi-extract @_ finished");
		diag("stdout:\n$stdout\nstderr:\n$stderr");
	}
	return ($exit, $stdout, $stderr);
}

my @DIRS = ('--data-dir', $data_dir->to_string, '--model-dir', $model_dir->to_string);

# _listing($dir) -> sorted names of every file under $dir
sub _listing {
	return [ sort map { $_->to_rel($_[0])->to_string } @{ Mojo::File->new($_[0])->list_tree({ hidden => 1 })->to_array } ];
}

my $t = Test::Mojo->new('Database::BI', { data_dir => $data_dir->to_string, model_dir => $model_dir->to_string });
$t->app->log->level('fatal');

my $L = 'l=' . url_escape('table:sales');

# _snapshot() -> what a reader sees of the dataset, from several routes
sub _snapshot {
	my %got;
	$t->get_ok("/export?$L&format=csv")->status_is(200);
	$got{export} = $t->tx->res->body;
	$t->get_ok("/pivot?$L&rows=region&m=" . url_escape('amount:sum:total'))->status_is(200);
	$got{pivot} = [ map { $_->all_text =~ s/\s+//gr }
		@{ Mojo::DOM->new($t->tx->res->body)->find('table tbody td')->to_array } ];
	$t->get_ok("/view/sales?sort=" . url_escape('First Name') . '&dir=desc&f=' . url_escape('region:ne:East'))->status_is(200);
	$got{view} = [ map { $_->all_text =~ s/\s+//gr }
		@{ Mojo::DOM->new($t->tx->res->body)->find('#bi-table tbody td')->to_array } ];
	return \%got;
}

sub _note {
	my $dom  = Mojo::DOM->new($t->tx->res->body);
	my $note = $dom->at('#accel-note');
	return $note ? ($note->attr('data-state'), $note->all_text) : ();
}

my $data_before = _listing($data_dir);
my $plain       = _snapshot();

subtest 'arguments' => sub {
	my ($code, $out, $err) = _cli(@DIRS);
	is $code, 2, 'nothing to do is a usage error';
	like $err, qr/give --spec, --all, --remove --spec or --list/, 'which says what to give';
	($code) = _cli(@DIRS, '--all', '--spec', 'table:sales');
	is $code, 2, '--all with --spec is one too';
	($code) = _cli(@DIRS, '--remove');
	is $code, 2, 'and --remove without a spec';
	($code, $out) = _cli('--help');
	is $code, 0, '--help is fine';
	($code, $out) = _cli(@DIRS, '--list');
	is $code, 0, '--list with nothing accelerated';
	like $out, qr/No dataset is accelerated/, 'says so';
	($code, $out) = _cli(@DIRS, '--all');
	is $code, 0, 'and so does --all';
	like $out, qr/No dataset is accelerated/;
};

subtest 'what cannot be accelerated' => sub {
	my ($code, $out, $err) = _cli(@DIRS, '--spec', 'table:nope');
	is $code, 1, 'a missing table fails';
	like $err, qr/Cannot accelerate "table:nope": it must be a table: or path: spec naming a local file/;
	($code, undef, $err) = _cli(@DIRS, '--spec', 'url:https://example.com/x.csv');
	is $code, 1, 'as does a URL';
	($code, undef, $err) = _cli(@DIRS, '--spec', 'table:store');
	is $code, 1, 'and a SQLite file';
	like $err, qr/it is a SQLite database already/;

	my $inside = $data_dir->child('models');
	($code, undef, $err) = _cli('--data-dir', $data_dir->to_string, '--model-dir', $inside->to_string, '--spec', 'table:sales');
	is $code, 1, 'a model_dir inside data_dir is refused';
	like $err, qr/the model store cannot be written/;
	ok !-e $inside, 'and nothing is made there';
	is_deeply _listing($data_dir), $data_before, 'nothing was written under data_dir';
};

subtest 'an accelerated dataset reads its extract, and answers the same' => sub {
	my ($code, $out, $err) = _cli(@DIRS, '--spec', 'table:sales');
	is $code, 0, 'bi-extract builds it' or diag $err;
	like $out, qr{\Atable:sales: 4 rows, 4 columns -> \S+[\\/]extracts[\\/][0-9a-f]{32}\.db \(built \d{4}-\d\d-\d\d \d\d:\d\d\)\n\z},
		'and prints what it built';
	my ($code2, $list) = _cli(@DIRS, '--list');
	is $list, "table:sales\n", '--list names it';

	is_deeply _snapshot(), $plain, 'the export, a pivot and a sorted, filtered page are unchanged';
	$t->get_ok('/view/sales')->status_is(200);
	my ($state, $text) = _note();
	is $state, 'fresh', 'the table page says it is accelerated';
	like $text, qr/Accelerated: read from an extract built \d{4}-\d\d-\d\d \d\d:\d\d/, 'and when it was built';
	$t->get_ok('/open?path=' . url_escape($data_dir->child('sales.csv')->to_string))->status_is(200);
	ok !(_note()), 'path: is a different spec, so /open reads the file';

	# Proof that the rows come from the extract: change one there.
	my ($x) = glob $model_dir->child('extracts', '*.db')->to_string;
	my $dbh = DBI->connect("dbi:SQLite:dbname=$x", '', '', { RaiseError => 1, PrintError => 0 });
	$dbh->do(q{UPDATE "extract" SET "First Name" = 'Zed' WHERE id = '1'});
	$dbh->disconnect;
	# Rows are cached by the file's mtime, to the second; a hand edit in the
	# second the extract was built would look unchanged.  bi-extract never
	# rewrites an extract with different rows under the same fingerprint.
	utime time - 100, time - 100, $x;
	$t->get_ok("/export?$L&format=csv")->status_is(200)->content_like(qr/\b1,North,10,Zed\b/,
		'a page is read from the extract');

	my ($pushed, $real) = (0, \&Database::BI::Model::DataSource::aggregate);
	no warnings 'redefine';
	local *Database::BI::Model::DataSource::aggregate = sub { $pushed++; return $real->(@_) };
	$t->get_ok("/pivot?$L&rows=region&m=" . url_escape('id:count:n'))->status_is(200);
	my $pushed_page = $t->tx->res->body;
	cmp_ok $pushed, '>', 0, 'an aggregate can be pushed to the extract, as to any SQLite source';
	{
		local $ENV{BI_FORCE_PERL_AGG} = 1;
		$t->get_ok("/pivot?$L&rows=region&m=" . url_escape('id:count:n'))->status_is(200);
		my $cells = sub { [ map { $_->all_text =~ s/\s+//gr } @{ Mojo::DOM->new($_[0])->find('table tbody td')->to_array } ] };
		is_deeply $cells->($t->tx->res->body), $cells->($pushed_page), 'and gives what the Perl fold does';
	}

	($code, $out) = _cli(@DIRS, '--all');
	is $code, 0, '--all rebuilds it';
	like $out, qr/\Atable:sales: 4 rows/;
	$t->get_ok("/export?$L&format=csv")->status_is(200);
	is $t->tx->res->body, $plain->{export}, 'from the file again';
	my @extracts = glob $model_dir->child('extracts', '*.db')->to_string;
	is scalar(@extracts), 1, 'one extract, in place of the old one';
};

subtest 'a changed file is read itself, and the page says the extract is stale' => sub {
	# A different size as well as a different time, so the fingerprint moves
	# even on a file system with a coarse clock.
	my $file = $data_dir->child('sales.csv');
	$file->spew($SALES . "5,West,50,Ed\n");
	utime time + 5, time + 5, $file->to_string;
	$t->get_ok('/view/sales')->status_is(200)->content_like(qr{<td[^>]*>West</td>}, 'the new row is there');
	my ($state, $text) = _note();
	is $state, 'stale', 'the page says the extract is stale';
	like $text, qr/the file has changed since its extract was built \(\d{4}-.*\), so the file itself was read/;
	like $text, qr{script/bi-extract --spec table:sales}, 'and how to rebuild it';
	$t->get_ok("/export?$L&format=csv")->status_is(200)->content_like(qr/5,West,50,Ed/, 'every route reads the file');

	my ($code) = _cli(@DIRS, '--spec', 'table:sales');
	is $code, 0, 'rebuilt';
	$t->get_ok('/view/sales')->status_is(200);
	is((_note())[0], 'fresh', 'and fresh again');
};

subtest 'deleting extracts/ costs nothing' => sub {
	$model_dir->child('extracts')->remove_tree;
	$t->get_ok("/export?$L&format=csv")->status_is(200)->content_like(qr/5,West,50,Ed/, 'the file is read');
	$t->get_ok('/view/sales')->status_is(200);
	is((_note())[0], 'stale', 'and the page says why');
	my ($code) = _cli(@DIRS, '--all');
	is $code, 0, 'and --all builds it back';
};

subtest 'path: specs, and --remove' => sub {
	my $spec = 'path:' . $data_dir->child('sales.csv')->to_string;
	my ($code, $out) = _cli(@DIRS, '--spec', $spec);
	is $code, 0, 'a path: spec can be accelerated';
	$t->get_ok('/open?path=' . url_escape($data_dir->child('sales.csv')->to_string))->status_is(200);
	is((_note())[0], 'fresh', 'and /open reads it from the extract');

	($code, $out) = _cli(@DIRS, '--remove', '--spec', 'table:sales', '--spec', $spec);
	is $code, 0, '--remove';
	like $out, qr/table:sales: no longer accelerated; its extract is removed/;
	is_deeply [ glob $model_dir->child('extracts', '*.db')->to_string ], [], 'both extracts are gone';
	$t->get_ok('/view/sales')->status_is(200);
	ok !(_note()), 'and the page says nothing';
	($code, $out) = _cli(@DIRS, '--remove', '--spec', 'table:sales');
	like $out, qr/table:sales: was not accelerated/, 'removing twice is harmless';
};

is_deeply _listing($data_dir), [ sort @$data_before ], 'nothing at all was written under data_dir';

done_testing;
