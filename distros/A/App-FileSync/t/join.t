use strict;
use warnings;
use Test::Most;

use File::Path qw(make_path);
use File::Spec;
use FindBin qw($Bin);

use lib 't/lib';
use TestSync;

my $T0 = 1_700_000_000;
my $admin = File::Spec->catfile($Bin, '..', 'bin', 'filesync-admin');

sub master_dir {
	my ($env) = @_;
	return File::Spec->catdir($env->{server}, 'master', 'docs');
}

sub files_only {
	my ($env, $dir) = @_;
	return [ grep { $_ ne '.filesync-root' } @{ $env->tree($dir) } ];
}

sub copies_named {
	my ($env, $side, $dir, $stem, $content) = @_;

	return grep {
		m{\A\Q$stem\E\.conflict-test-1-\d{8}T\d{6}Z(?:-\d+)?\.txt\z}
			&& $env->read_file($side, $_) eq $content
	} @{ $env->tree($dir) };
}

# ---------------------------------------------- first sync merges both trees
{
	my $env = TestSync->new_env();

	# Master: a file of its own, a conflict it should win, a conflict it should
	# lose, and one path both sides already agree on.
	$env->write_file('server', 'master-only.txt', "from master\n", $T0);
	$env->write_file('server', 'dir/notes.txt', "master notes\n", $T0);
	$env->write_file('server', 'shared.txt', "master version\n", $T0 + 200);
	$env->write_file('server', 'client-wins.txt', "older master\n", $T0 + 100);
	$env->write_file('server', 'same.txt', "identical\n", $T0);

	# Client: a file of its own, the losing side of one conflict, the winning
	# side of another, and a copy of the agreed path with a different mtime.
	$env->write_file('client', 'client-only.txt', "from client\n", $T0);
	$env->write_file('client', 'shared.txt', "client version\n", $T0 + 100);
	$env->write_file('client', 'client-wins.txt', "newer client\n", $T0 + 300);
	$env->write_file('client', 'same.txt', "identical\n", $T0 + 50);

	my $client_before = $env->snapshot($env->{client});
	my $master_before = $env->snapshot(master_dir($env));

	# The documented first step: inspect the plan without touching either tree.
	my $dry = $env->sync(dry_run => 1);
	is($dry->{exit}, 3, 'the dry run reports the conflicts it found');
	is($dry->{summary}{pulled}, 2, 'the dry run plans both master-only files as pulls');
	is($dry->{summary}{pushed}, 1, 'the dry run plans the client-only file as a push');
	is($dry->{summary}{conflicts}, 2, 'the dry run plans both disagreements as conflicts');
	is_deeply($env->snapshot($env->{client}), $client_before,
		'the dry run leaves the client tree untouched');
	is_deeply($env->snapshot(master_dir($env)), $master_before,
		'the dry run leaves the master untouched');

	# The documented second step: merge, with section 8.3 deciding each conflict.
	my $join = $env->sync();
	is($join->{exit}, 3, 'the join exits 3 because it kept conflict copies');
	is($join->{summary}{pulled}, 2, 'both master-only files were pulled');
	is($join->{summary}{pushed}, 1, 'the client-only file was pushed');
	is($join->{summary}{conflicts}, 2, 'both disagreements were resolved');

	is($env->read_file('client', 'master-only.txt'), "from master\n",
		'the master-only file reached the client');
	is($env->read_file('server', 'client-only.txt'), "from client\n",
		'the client-only file reached the master');
	is($env->read_file('client', 'dir/notes.txt'), "master notes\n",
		'a nested master file was pulled');

	is($env->read_file('client', 'shared.txt'), "master version\n",
		'the newer master version won its conflict');
	is($env->read_file('server', 'shared.txt'), "master version\n",
		'the master keeps the winning version');

	my @shared_copies = copies_named($env, 'client', $env->{client}, 'shared',
		"client version\n");
	is(scalar @shared_copies, 1,
		'the losing client version was preserved beside the winner');

	is($env->read_file('server', 'client-wins.txt'), "newer client\n",
		'the newer client version won its conflict');
	is($env->read_file('client', 'client-wins.txt'), "newer client\n",
		'the client keeps its winning version');

	my @master_copies = copies_named($env, 'server', master_dir($env),
		'client-wins', "older master\n");
	is(scalar @master_copies, 1,
		'the losing master version was preserved in the master');

	is($env->read_file('client', 'same.txt'), "identical\n",
		'the agreed path was left alone');
	is($env->read_file('server', 'same.txt'), "identical\n",
		'the master copy of the agreed path is unchanged');

	# Conflict copies are ordinary files and propagate on later runs.
	my $propagate = $env->sync();
	is($propagate->{summary}{pushed}, 1,
		'the next run pushes the client-side conflict copy');
	is($propagate->{summary}{pulled}, 1,
		'and pulls the master-side conflict copy');
	is($propagate->{summary}{conflicts}, 0, 'the resolved conflicts do not repeat');

	my $stable = $env->sync();
	is($stable->{summary}{pulled}, 0, 'nothing is left to pull');
	is($stable->{summary}{pushed}, 0, 'nothing is left to push');
	is($stable->{summary}{conflicts}, 0, 'no conflict returns');

	is_deeply(files_only($env, $env->{client}), files_only($env, master_dir($env)),
		'both trees hold the same files once the copies have propagated');

	for my $copy (@shared_copies, @master_copies) {
		ok($env->exists_in('client', $copy), "the client has $copy");
		ok($env->exists_in('server', $copy), "the master has $copy");
	}
}

# ------------------------------------------- joining with an empty root
# The client has no base, just as after `filesync init` on a new machine or
# `filesync-admin client forget`.
{
	my $env = TestSync->new_env();

	$env->write_file('server', 'one.txt', "one\n", $T0);
	$env->write_file('server', 'nested/two.txt', "two\n", $T0);
	$env->write_file('server', 'nested/deeper/three.txt', "three\n", $T0);

	my $client_before = $env->snapshot($env->{client});

	# The dry run an operator is told to do first sees only pulls.
	my $dry = $env->sync(dry_run => 1);
	is($dry->{exit}, 0, 'an empty root has nothing to conflict about');
	is($dry->{summary}{pulled}, 3, 'the dry run plans to pull the master files');
	is($dry->{summary}{pushed}, 0, 'the dry run plans no pushes');
	is_deeply($env->snapshot($env->{client}), $client_before,
		'the dry run writes nothing into the empty root');

	my $join = $env->sync();
	is($join->{exit}, 0, 'the first sync of an empty root exits 0');
	is($join->{summary}{pulled}, 3, 'the first sync pulls the master');
	is($join->{summary}{pushed}, 0, 'and pushes nothing');
	is($join->{summary}{conflicts}, 0, 'an empty root has no conflicts');
	is_deeply(files_only($env, $env->{client}), files_only($env, master_dir($env)),
		'the client now mirrors the master file for file');

	# Only the files copied in afterwards are added to the master.
	$env->write_file('client', 'local.txt', "local only\n", $T0 + 100);
	$env->write_file('client', 'nested/local.txt', "nested local\n", $T0 + 100);
	my $add = $env->sync();
	is($add->{summary}{pushed}, 2, 'the files copied in after the join are pushed');
	is($add->{summary}{pulled}, 0, 'nothing is pulled back over them');
	is($env->read_file('server', 'local.txt'), "local only\n",
		'the added file reached the master');
	is($env->read_file('server', 'nested/local.txt'), "nested local\n",
		'the added nested file reached the master');

	# A later master edit still comes down, proving the join left a working base.
	$env->write_file('server', 'one.txt', "one changed\n", $T0 + 200);
	my $later = $env->sync();
	is($later->{summary}{pulled}, 1, 'a later master edit is pulled');
	is($env->read_file('client', 'one.txt'), "one changed\n",
		'the edit reached the joined client');
}

# ------------------------------------- rejoining after client forget
{
	my $env = TestSync->new_env();

	# Give the client a history and a server-side base first.
	$env->write_file('client', 'shared.txt', "original\n", $T0);
	$env->write_file('client', 'client-owned.txt', "first\n", $T0);
	my $first = $env->sync();
	is($first->{summary}{pushed}, 2, 'the client establishes a base');
	is($first->{summary}{pulled}, 0, 'with nothing to pull');

	my $base = $env->meta_path('clients', 'test-1.json');
	ok(-e $base, 'the server stored a base for the client');

	# Both sides move on before the client is forgotten.
	$env->write_file('client', 'shared.txt', "newer client\n", $T0 + 300);
	$env->write_file('client', 'client-owned.txt', "client edit\n", $T0 + 100);
	$env->write_file('client', 'client-only.txt', "client only\n", $T0 + 100);

	$env->write_file('server', 'shared.txt', "older master\n", $T0 + 200);
	$env->write_file('server', 'client-owned.txt', "master edit\n", $T0 + 200);
	$env->write_file('server', 'master-only.txt', "master only\n", $T0 + 100);

	my $output = `$^X $admin --root $env->{server} client forget test-1 --repo docs 2>&1`;
	is($?, 0, 'client forget exits 0');
	like($output, qr/Forgot test-1/, 'the admin command reports the forgotten client');
	ok(!-e $base, 'the server no longer stores a base for the client');

	# With no base the next run is a join, not an ordinary incremental sync.
	my $rejoin = $env->sync();
	is($rejoin->{exit}, 3, 'the rejoin keeps conflict copies');
	is($rejoin->{summary}{pulled}, 1, 'the master-only file is pulled');
	is($rejoin->{summary}{pushed}, 1, 'the client-only file is pushed');
	is($rejoin->{summary}{conflicts}, 2, 'both diverged paths conflict again');

	is($env->read_file('client', 'master-only.txt'), "master only\n",
		'the master-only file reached the forgotten client');
	is($env->read_file('server', 'client-only.txt'), "client only\n",
		'the client-only file reached the master');

	is($env->read_file('server', 'shared.txt'), "newer client\n",
		'the newer client version won its conflict');
	is($env->read_file('client', 'shared.txt'), "newer client\n",
		'the client keeps its winning version');
	my @master_copies = copies_named($env, 'server', master_dir($env), 'shared',
		"older master\n");
	is(scalar @master_copies, 1,
		'the losing master version was preserved in the master');

	is($env->read_file('client', 'client-owned.txt'), "master edit\n",
		'the newer master version won its conflict');
	is($env->read_file('server', 'client-owned.txt'), "master edit\n",
		'the master keeps the winning version');
	my @client_copies = copies_named($env, 'client', $env->{client}, 'client-owned',
		"client edit\n");
	is(scalar @client_copies, 1,
		'the losing client version was preserved beside the winner');

	# As with any join, the copies propagate on later runs and then settle.
	my $propagate = $env->sync();
	is($propagate->{summary}{pushed}, 1,
		'the next run pushes the client-side conflict copy');
	is($propagate->{summary}{pulled}, 1,
		'and pulls the master-side conflict copy');
	is($propagate->{summary}{conflicts}, 0, 'the repeats do not conflict');

	for my $copy (@client_copies, @master_copies) {
		ok($env->exists_in('client', $copy), "the client has $copy");
		ok($env->exists_in('server', $copy), "the master has $copy");
	}

	my $stable = $env->sync();
	is($stable->{summary}{pulled}, 0, 'nothing is left to pull after the rejoin');
	is($stable->{summary}{pushed}, 0, 'nothing is left to push after the rejoin');
	is_deeply(files_only($env, $env->{client}), files_only($env, master_dir($env)),
		'the rejoined client and master hold the same files');
}

# ------------------------------------- rejoining a forgotten replica
# A replica never pushes and never keeps conflict copies: after a forget it
# must still mirror the master, overwriting local edits and removing extras.
{
	my $env = TestSync->new_env(client_id => 'backup-1', role => 'replica');

	$env->write_file('server', 'a.txt', "master a\n", $T0);
	$env->write_file('server', 'sub/b.txt', "master b\n", $T0 + 1);
	make_path($env->server_path('empty'));

	my $first = $env->sync();
	is($first->{summary}{pulled}, 3, 'the replica first mirrors the files and empty dir');
	is($first->{summary}{pushed}, 0, 'and never pushes');

	my $base = $env->meta_path('clients', 'backup-1.json');
	ok(-e $base, 'the server stored a base for the replica');

	# Both sides change before the replica is forgotten: the master edits one
	# file, adds one and removes one; the replica edits the same file, adds an
	# extra and loses the empty directory.
	$env->write_file('server', 'a.txt', "master changed\n", $T0 + 300);
	$env->write_file('server', 'master-only.txt', "master only\n", $T0 + 100);
	unlink $env->server_path('sub/b.txt');

	# The replica's edit is newer than the master's, so a normal client would
	# win this path; a replica must still discard its version.
	$env->write_file('client', 'a.txt', "replica edit\n", $T0 + 400);
	$env->write_file('client', 'rogue.txt', "not on the master\n", $T0 + 200);
	rmdir $env->client_path('empty') or die "Cannot remove the replica empty dir: $!";

	my $output = `$^X $admin --root $env->{server} client forget backup-1 --repo docs 2>&1`;
	is($?, 0, 'the replica can be forgotten');
	like($output, qr/Forgot backup-1/, 'the admin command names the replica');
	ok(!-e $base, 'the stored base is gone');

	my $rejoin = $env->sync();
	is($rejoin->{summary}{pulled}, 4,
		'the rejoin pulls the changed, added and missing-directory entries');
	is($rejoin->{summary}{pushed}, 0, 'the forgotten replica still never pushes');
	is($rejoin->{summary}{deleted}, 2, 'it removes its extra and the master-deleted file');
	is($rejoin->{summary}{conflicts}, 0, 'a replica has no conflicts to resolve');
	is($rejoin->{exit}, 3, 'the removals are reported as warnings');

	is($env->read_file('client', 'a.txt'), "master changed\n",
		'the master version overwrites the local edit');
	is($env->read_file('server', 'a.txt'), "master changed\n",
		'the replica does not overwrite the master');
	is($env->read_file('client', 'master-only.txt'), "master only\n",
		'the master-only file reached the replica');
	ok(!$env->exists_in('client', 'rogue.txt'), 'the replica extra was removed');
	ok(!$env->exists_in('client', 'sub/b.txt'), 'the master-deleted file was removed');
	ok(-d $env->client_path('empty'), 'the missing empty directory was restored');

	my @conflicts = grep { /\.conflict-/ }
		(@{ $env->tree($env->{client}) }, @{ $env->tree(master_dir($env)) });
	is(scalar @conflicts, 0, 'a replica never keeps conflict copies');

	my $stable = $env->sync();
	is($stable->{summary}{pulled}, 0, 'nothing is left to pull');
	is($stable->{summary}{deleted}, 0, 'nothing is left to delete');
	is($stable->{summary}{conflicts}, 0, 'still no conflict');
	is_deeply(files_only($env, $env->{client}), files_only($env, master_dir($env)),
		'the rejoined replica mirrors the master');

	# Mirror semantics still hold on later runs: a new local extra is removed
	# and a master edit is pulled, with the replica still never pushing.
	$env->write_file('client', 'another-rogue.txt', "extra\n", $T0 + 400);
	$env->write_file('server', 'a.txt', "master again\n", $T0 + 500);
	my $later = $env->sync();
	is($later->{summary}{pulled}, 1, 'a later master edit is pulled');
	is($later->{summary}{deleted}, 1, 'a later local extra is removed');
	is($later->{summary}{pushed}, 0, 'the replica still pushes nothing');
	is($env->read_file('client', 'a.txt'), "master again\n",
		'the later master edit is mirrored');
	ok(!$env->exists_in('client', 'another-rogue.txt'), 'the later extra is gone');
}

# A forgotten replica must not let an empty master wipe a populated mirror.
# With no base there is no baseline for the percentage limit, so the absolute
# max_deletes guard is the protection that matters here.
{
	my $env = TestSync->new_env(
		client_id => 'backup-1', role => 'replica', max_deletes => 3,
	);

	$env->write_file('server', "file$_.txt", "master $_\n", $T0 + $_)
		for 1 .. 5;

	my $first = $env->sync();
	is($first->{summary}{pulled}, 5, 'the replica mirrors the five master files');
	my $base = $env->meta_path('clients', 'backup-1.json');
	ok(-e $base, 'the replica has a stored base');

	# The master is emptied, then the replica is forgotten.  Without a base the
	# only surviving limit is max_deletes.
	unlink $env->server_path("file$_.txt") for 1 .. 5;

	my $output = `$^X $admin --root $env->{server} client forget backup-1 --repo docs 2>&1`;
	is($?, 0, 'the replica can be forgotten');
	ok(!-e $base, 'its base is gone');

	my $before = $env->snapshot($env->{client});
	my $error;
	eval { $env->sync(); 1 } or $error = $@;
	ok($error, 'the rejoin is refused without --force');
	like($error, qr/refusing to delete 5 files \(limit is 3\)/,
		'the refusal names the deletion count and the guard');

	is_deeply($env->snapshot($env->{client}), $before,
		'the refused rejoin leaves the local mirror untouched');
	ok($env->exists_in('client', 'file1.txt'), 'the first local file is still there');
	ok(!$env->exists_in('server', 'file1.txt'), 'the master is still empty');

	# --force is the documented escape hatch and lets the mirror complete.
	my $forced = $env->sync(force => 1);
	is($forced->{summary}{deleted}, 5, '--force performs the five deletions');
	is($forced->{summary}{pushed}, 0, 'the replica still pushes nothing');
	is_deeply(files_only($env, $env->{client}), [],
		'the explicitly forced mirror is now empty');
}

done_testing();
