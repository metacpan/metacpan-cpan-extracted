#!/usr/bin/env perl

# The data_dir invariant (BI-Phase-3.md, section 11, item 4).
#
# Database::BI reads the user's data files and must never write to them.  Its
# own state -- calculated-field models and saved analyses -- belongs in
# model_dir (default <app home>/.bi/), which is a different place on purpose: a
# store beside a CSV would be a file the user did not ask for, in a directory
# they chose for data.  BI-ROADMAP.md section 5 makes that an invariant; this
# test is what holds the code to it.
#
# The test builds a data_dir of its own, snapshots every entry in it (path,
# size, mtime and a digest), runs a full create/render/export cycle through
# Test::Mojo, and asserts the listing is identical afterwards.  Size and mtime
# alone would not be enough: an integer-seconds mtime cannot see a rewrite that
# happens within the same second, which is exactly what a test like this does,
# so a digest is part of the comparison.
#
# The cycle deliberately includes one write -- POST /calc/save, which persists a
# model -- because a cycle that never writes anything would pass this test
# without proving anything.  The checks after the comparison assert that the
# app-owned store did change, so a broken cycle cannot masquerade as a pass.
# GET /export and the saved analysis's JSON export are included because
# streaming an export is the request most likely to be implemented by staging a
# file first.  POST /export, which writes wherever the user asks it to, is a
# user-directed write and is deliberately not part of this cycle.
#
# A block after that tests the comparison itself, so that a snapshot which
# silently walked nothing cannot make the main assertion vacuous.
#
# The other half of the invariant is what happens when the two directories are
# made to overlap -- a model_dir left inside a data_dir the user set, or a
# config edited by hand.  Every store path refuses to write in that case (it
# returns undef before it even calls mkdir), so the blocks at the end of this
# file run the same cycle against apps whose model_dir IS inside data_dir, in
# five different spellings of the same overlap, and assert that the refusal
# reports itself, that nothing at all appears under data_dir, and -- just as
# important -- that the read-only views keep working: a guard that broke the app
# would be worse than the write it prevents.  Two of the five spellings go
# through a symlink, because a store that reaches data_dir by a link is the same
# store in the same place and a string comparison cannot see it: that hole was
# real (both stores were written inside data_dir) until the guard resolved its
# paths, and these placements are here to keep it closed.
#
# A final block points the store at a directory beside data_dir whose path
# shares its prefix, and writes to it, so that a guard which refused too much
# could not pass either.

use strict;
use warnings;

use FindBin;
use Test::Most;
use Test::Mojo;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Mojo::File;
use Mojo::JSON qw(encode_json);
use Mojo::Util qw(md5_sum);

# ---------------------------------------------------------------------------
# The fixture: a data directory the application only ever reads
# ---------------------------------------------------------------------------
#
# data_dir is resolved relative to the application home, so the fixture has to
# live there.  Its name matches the dist's "Database-.*" MANIFEST.SKIP rule, and
# CLEANUP removes it whether the test passes, fails or dies part way through.

# realpath, not to_abs: the application's home is the resolved dist root, and
# a path still carrying "t/.." would never compare equal to it.
my $home = Mojo::File->new("$FindBin::Bin/..")->realpath->to_string;

my $data_dir = tempdir(
	DIR      => $home,
	TEMPLATE => 'Database-Invariant-XXXXXX',
	CLEANUP  => 1,
);

Mojo::File->new($data_dir)->child('sales.csv')->spurt(
	"id,product,region,amount\n"
	. "1,Widget,North,250\n"
	. "2,Gadget,South,150\n"
	. "3,Widget,South,300\n"
);
# A subdirectory as well, so the snapshot walk has to recurse.
make_path("$data_dir/nested");
Mojo::File->new($data_dir)->child('nested')->child('widgets.csv')
	->spurt("id,label\n1,alpha\n");

my $model_dir = tempdir(CLEANUP => 1);

# data_dir is passed at construction, not afterwards: open_table closes over the
# directory it was given at startup, so a later config change would leave the
# app reading one directory while this test watched another.
my $t = Test::Mojo->new('Database::BI', {
	data_dir  => Mojo::File->new($data_dir)->to_rel($home),
	model_dir => $model_dir,
});

# ---------------------------------------------------------------------------
# Preconditions -- a test that passes for the wrong reason is worse than none
# ---------------------------------------------------------------------------

subtest 'the fixture is the directory the application actually reads' => sub {
	# Normalize path separators: realpath on Windows returns forward slashes
	# while to_abs->to_string returns backslashes -- both name the same path.
	my $app_home_str = $t->app->home->to_abs->to_string;
	$app_home_str =~ s{\\}{/}g;
	(my $exp_home_str = $home) =~ s{\\}{/}g;
	is $app_home_str, $exp_home_str,
		'the application home is the directory this test is watching';

	my $resolved = $t->app->home->child($t->app->config->{data_dir});
	my $resolved_str = $resolved->to_abs->to_string;
	my $fixture_str  = Mojo::File->new($data_dir)->to_abs->to_string;
	$resolved_str =~ s{\\}{/}g;
	$fixture_str  =~ s{\\}{/}g;
	is $resolved_str, $fixture_str,
		'data_dir resolves to the fixture';

	# Proof it is read, not merely configured: the home page scans data_dir.
	$t->get_ok('/')->status_is(200)->content_like(qr/sales/,
		'the home page lists a table from the fixture');

	my $store_abs = Mojo::File->new($model_dir)->to_abs->to_string;
	my $data_abs  = Mojo::File->new($data_dir)->to_abs->to_string;
	isnt index($store_abs, $data_abs . '/'), 0,
		'the app-owned store is not inside data_dir, so a write here would be a bug';
};

# ---------------------------------------------------------------------------
# The snapshot
# ---------------------------------------------------------------------------

# _snapshot($root) -> { relative path => 'dir:<mtime>' | '<size>:<mtime>:<digest>' }
sub _snapshot {
	my ($root) = @_;

	my %snapshot;
	# The seed is the empty string -- the root itself -- so the condition has to
	# test definedness rather than truth, or the walk never starts.
	my @pending = ('');
	while (defined(my $rel = shift @pending)) {
		my $dir = length $rel ? "$root/$rel" : $root;
		opendir(my $dh, $dir) or die "opendir($dir): $!";
		for my $entry (readdir $dh) {
			next if $entry eq '.' || $entry eq '..';
			my $path = "$dir/$entry";
			my $key  = length $rel ? "$rel/$entry" : $entry;
			if (-d $path) {
				$snapshot{$key} = 'dir:' . (stat $path)[9];
				push @pending, $key;
			} elsif (-f $path) {
				my @stat = stat $path;
				$snapshot{$key} = join(':',
					$stat[7], $stat[9], md5_sum(Mojo::File->new($path)->slurp));
			}
		}
		closedir $dh;
	}

	return \%snapshot;
}

# _differences($before, $after) -> list of human-readable changes
sub _differences {
	my ($before, $after) = @_;

	my @changed;
	for my $key (sort keys %$after) {
		push @changed, ($before->{$key} // '')
			eq $after->{$key} ? () : "new/changed $key";
	}
	push @changed, map { "removed $_" } grep { !exists $after->{$_} } sort keys %$before;

	return @changed;
}

my $before = _snapshot($data_dir);

# ---------------------------------------------------------------------------
# The cycle: create, render, export
# ---------------------------------------------------------------------------

my $analysis_id;

subtest 'a create/render/export cycle leaves data_dir untouched' => sub {
	# Reads: the home scan, a table view, a chart pipelined from the table.
	$t->get_ok('/view/sales')->status_is(200);
	$t->get_ok('/bar?l=table:sales&cat=region&val=amount')->status_is(200);

	# A write -- but to the app-owned store, not to the data.
	$t->post_ok('/calc/save',
		form => { l => 'table:sales', name => 'doubled', expr => 'amount * 2' })
	  ->status_is(200)->json_is('/ok', 1, 'model saved to the store');

	# Create the analysis, render its canvas, export the document.
	$analysis_id = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Data dir invariant',
			datasets => [ { spec => 'table:sales', alias => 'left' } ],
			visuals  => [ { kind => 'table', encode => {}, title => 'Sales' } ],
		})
	)->status_is(201)->tx->res->json->{id};
	ok $analysis_id, 'analysis created';

	$t->get_ok("/a/$analysis_id")->status_is(200);
	$t->get_ok("/api/analyses/$analysis_id/export")->status_is(200);

	# Streaming exports, which must not stage a file on the way out.
	$t->get_ok('/export?l=table:sales&format=csv')->status_is(200);
	$t->get_ok('/export?l=table:sales&format=json')->status_is(200);
	$t->get_ok('/export?l=table:sales&format=sqlite')->status_is(200);
};

my $after = _snapshot($data_dir);

is_deeply [ _differences($before, $after) ], [],
	'no file under data_dir was created, changed or removed by the cycle';

# ---------------------------------------------------------------------------
# ... and the cycle really did write: to the store
# ---------------------------------------------------------------------------

subtest 'the same cycle did write -- to the app-owned store' => sub {
	my $store = Mojo::File->new($model_dir);

	my $analyses = $store->child('analyses.json');
	ok -f $analyses, 'the analysis store exists';
	like $analyses->slurp, qr/\Q$analysis_id\E/,
		'the analysis is in the store, not beside the data';

	my $models = $store->child('models.json');
	ok -f $models, 'the model store exists';
	like $models->slurp, qr/doubled/,
		'the calculated field is in the store, not beside the data';
};

# ---------------------------------------------------------------------------
# The comparison has to be able to fail
# ---------------------------------------------------------------------------

subtest 'the snapshot detects a file appearing in data_dir' => sub {
	my $probe = Mojo::File->new($data_dir)->child('probe.csv');

	$probe->spurt("a\n");
	is_deeply [ _differences($after, _snapshot($data_dir)) ], ['new/changed probe.csv'],
		'a file created in data_dir is detected';

	# Same length, so size cannot be what gives it away; if this and the digests
	# land in the same second, the digest is the only evidence left.
	$probe->spurt("b\n");
	is_deeply [ _differences($after, _snapshot($data_dir)) ], ['new/changed probe.csv'],
		'a file rewritten with the same length is detected';

	$probe->remove;
	is_deeply [ _differences($after, _snapshot($data_dir)) ], [],
		'the comparison is quiet once the probe is gone';
};

# ---------------------------------------------------------------------------
# A model_dir inside data_dir is refused, not obeyed
# ---------------------------------------------------------------------------

subtest 'model_dir inside data_dir: the stores refuse and the app stays read-only' => sub {
	my $relative = Mojo::File->new($data_dir)->to_rel($home);
	my $before   = _snapshot($data_dir);

	# A directory under the app home to hold the symlinks, so that CLEANUP takes
	# them with it however this test ends.
	my $links = tempdir(
		DIR      => $home,
		TEMPLATE => 'Database-Invariant-links-XXXXXX',
		CLEANUP  => 1,
	);

	# Five ways of naming the same overlap.  Two of them are not visible to a
	# string comparison at all: a symlink outside data_dir that points at it, and
	# a data_dir that is itself a symlink while the store names the directory it
	# resolves to.  Both are the same store in the same place, so both have to be
	# refused; the placements are left out on a host that cannot make symlinks.
	my $store_link = Mojo::File->new($links)->child('store-link')->to_string;
	my $dir_link   = Mojo::File->new($links)->child('data-link')->to_string;
	my $symlinks   = eval {
	symlink($data_dir => $store_link) && symlink($data_dir => $dir_link)
	# Verify that Cwd::realpath actually resolves the symlink on this platform
	# (Windows may create the symlink but not traverse it, so the overlap guard
	# would not trigger and the placement tests would give false failures).
	&& do {
		require Cwd;
		my $t = Cwd::realpath($store_link) // '';
		my $r = Cwd::realpath($data_dir)   // '';
		$t && $r && File::Spec->canonpath($t) eq File::Spec->canonpath($r);
	}
} ? 1 : 0;

	my @placements = (
		[ 'the data_dir itself',              $relative, Mojo::File->new($relative)->to_string ],
		[ 'a relative path inside it',        $relative, Mojo::File->new($relative, '.bi')->to_string ],
		[ 'an absolute path inside it',       $relative, Mojo::File->new($data_dir)->child('bi-store')->to_string ],
	);
	push @placements, (
		[ 'a symlink to data_dir',            $relative, Mojo::File->new($store_link)->to_rel($home) ],
		[ 'data_dir reached through a link',  Mojo::File->new($dir_link)->to_rel($home),
		                                              Mojo::File->new($data_dir)->child('.bi')->to_string ],
	) if $symlinks;

	for my $placement (@placements) {
		my ($what, $app_data_dir, $store) = @$placement;

		subtest "model_dir is $what" => sub {
			my $app = Test::Mojo->new('Database::BI', {
				data_dir  => $app_data_dir,
				model_dir => $store,
			});

			# The guard's only sign of life is a carp, so collect what it says
			# rather than let it scroll past: a silent refusal would leave a
			# user wondering why their calculated field never came back.
			my @warned;
			local $SIG{__WARN__} = sub { push @warned, @_ };

			# A write each store would normally take: a calculated field and a
			# saved analysis.
			$app->post_ok('/calc/save',
				form => { l => 'table:sales', name => 'tripled', expr => 'amount * 3' })
			  ->status_is(200)->json_is('/ok', 1);

			$app->post_ok('/api/analyses',
				{ 'Content-Type' => 'application/json' },
				encode_json({
					name     => 'Refused store',
					datasets => [ { spec => 'table:sales', alias => 'left' } ],
				})
			)->status_is(503)->json_like('/error', qr/not writable/,
				'analysis storage is reported unavailable');

			# Neither store took the write: the field is not there to be listed,
			# and the analysis is not there to be read back or listed either.
			$app->get_ok('/calc/list?l=table:sales')->status_is(200)
			  ->json_is('/fields', {}, 'the refused model write left no field behind');
			$app->get_ok('/api/analyses')->status_is(200)
			  ->json_is('/analyses', [], 'no analysis was stored');
			$app->get_ok('/api/analyses/abcd123456')
			  ->status_is(404, 'and no analysis can be read back');

			# The read-only views carry on as if none of this had happened: the
			# data directory is read for data, and the store is optional.
			$app->get_ok('/')->status_is(200)
			  ->content_like(qr/sales/, 'the home page still lists the fixture table');
			$app->get_ok('/view/sales')->status_is(200)
			  ->content_like(qr/Widget/, 'the table view still renders rows');
			$app->get_ok('/bar?l=table:sales&cat=region&val=amount')
			  ->status_is(200, 'a chart pipelined from the table still renders');
			$app->get_ok('/export?l=table:sales&format=csv')->status_is(200)
			  ->content_like(qr/Widget/, 'a streaming export still works');

			my $warnings = join('', @warned);
			like $warnings, qr/model_dir is inside data_dir; skipping model file write/,
				'the model store refusal was reported';
			like $warnings, qr/model_dir is inside data_dir; skipping analyses file write/,
				'the analysis store refusal was reported';
		};
	}

	# ... and nothing was written there: no store directory (not even an empty
	# one), no store file anywhere below data_dir, and no entry under it created,
	# changed or removed.
	ok !-e Mojo::File->new($data_dir)->child('bi-store')->to_string,
		'the absolute store directory inside data_dir was never created';
	ok !-e Mojo::File->new($home)->child($relative, '.bi')->to_string,
		'the relative store directory inside data_dir was never created either';
	if ($symlinks) {
		ok -l $store_link, 'the store is still a symlink to data_dir, not a directory of ours';
		ok !-e Mojo::File->new($data_dir)->child('models.json')->to_string,
			'the symlinked store wrote nothing into data_dir';
	}

	is_deeply [ grep { m{\.json\z} } keys %{ _snapshot($data_dir) } ], [],
		'no store file exists anywhere under data_dir';

	is_deeply [ _differences($before, _snapshot($data_dir)) ], [],
		'nothing under data_dir was created, changed or removed by the refused writes';

	# The guard is a prefix test, and it has to be a prefix test *with the
	# separator*: a store beside data_dir whose path merely begins with data_dir's
	# characters is not inside it and must still be written to.  Without this the
	# guard could be over-broad and still pass everything above -- refusing a
	# store that is legitimately outside, which is the same bug from the other
	# side.  The name is built from data_dir's own basename so the two paths share
	# every character as far as the separator.
	my $sibling = tempdir(
		DIR      => $home,
		TEMPLATE => Mojo::File->new($data_dir)->basename . '-store-XXXXXX',
		CLEANUP  => 1,
	);

	subtest 'a store beside data_dir, sharing its prefix, is written to' => sub {
		my $app = Test::Mojo->new('Database::BI', {
			data_dir  => $relative,
			model_dir => $sibling,
		});

		# This is the same cycle the refused placements ran, against a store the
		# guard allows: the writes land, so the assertions above are measuring the
		# refusal and not an app that never writes at all.
		$app->post_ok('/calc/save',
			form => { l => 'table:sales', name => 'tripled', expr => 'amount * 3' })
		  ->status_is(200)->json_is('/ok', 1);
		$app->get_ok('/calc/list?l=table:sales')->status_is(200)
		  ->json_is('/fields/tripled', 'amount * 3', 'the field was stored beside the data');

		my $id = $app->post_ok('/api/analyses',
			{ 'Content-Type' => 'application/json' },
			encode_json({
				name     => 'Written beside the data',
				datasets => [ { spec => 'table:sales', alias => 'left' } ],
			})
		)->status_is(201)->tx->res->json->{id};
		ok $id, 'analysis created';
		$app->get_ok("/api/analyses/$id")->status_is(200)
		  ->json_is('/name', 'Written beside the data', 'and it reads back');

		ok -f Mojo::File->new($sibling, 'models.json')->to_string,
			'the model store exists beside data_dir';
		ok -f Mojo::File->new($sibling, 'analyses.json')->to_string,
			'the analysis store exists beside data_dir';
	};
};

done_testing;
