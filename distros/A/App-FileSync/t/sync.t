use strict;
use warnings;
use Test::Most;
use Test::Exception;

use File::Path qw(make_path);
use File::Spec;

use lib 't/lib';
use TestSync;

my $T0 = 1_700_000_000;

# ---------------------------------------------------------------- basic sync
{
	my $env = TestSync->new_env();

	$env->write_file('client', 'a.txt', "alpha\n", $T0);
	$env->write_file('client', 'sub/b.bin', "\x00\x01\x02\xff", $T0 + 10);
	make_path(File::Spec->catdir($env->{client}, 'empty'));
	utime($T0, $T0, File::Spec->catdir($env->{client}, 'empty'));

	my $result = $env->sync();
	is($result->{summary}{pushed}, 3, 'two files and one empty directory pushed');
	is($result->{exit}, 0, 'a clean sync exits 0');
	is($env->read_file('server', 'a.txt'), "alpha\n", 'file content reached the master');
	ok($env->exists_in('server', 'sub/b.bin'), 'nested file reached the master');
	ok($env->exists_in('server', 'empty'), 'empty directory reached the master');
	is((stat($env->server_path('a.txt')))[9], $T0, 'mtime preserved on the master');

	my $again = $env->sync();
	is($again->{summary}{pushed}, 0, 'second run pushes nothing');
	is($again->{summary}{pulled}, 0, 'second run pulls nothing');
	is($again->{exit}, 0, 'second run is clean');

	# Master-side edit is pulled.
	$env->write_file('server', 'a.txt', "changed on the server\n", $T0 + 100);
	my $pull = $env->sync();
	is($pull->{summary}{pulled}, 1, 'master-side change pulled');
	is($env->read_file('client', 'a.txt'), "changed on the server\n", 'client content updated');

	# Client-side delete goes to the server trash.
	unlink $env->client_path('sub/b.bin');
	my $delete = $env->sync();
	is($delete->{summary}{deleted}, 1, 'client deletion propagated');
	ok(!$env->exists_in('server', 'sub/b.bin'), 'file removed from the master');

	my @trashed = glob(File::Spec->catfile($env->{server}, '.filesync', 'repos', 'docs',
		'trash', '*', '*', '*', 'sub', 'b.bin'));
	ok(@trashed, 'deleted file is in the server trash');
	is(do { local $/; open my $fh, '<', $trashed[0] or die $!; <$fh> }, "\x00\x01\x02\xff",
		'trash keeps the content');

	my @journal = glob(File::Spec->catfile($env->{server}, '.filesync', 'repos', 'docs',
		'journal', '*.jsonl'));
	ok(@journal, 'a journal exists');
	my $journal_text = do { local $/; open my $fh, '<', $journal[0] or die $!; <$fh> };
	like($journal_text, qr/"action":"push"/, 'pushes are journaled');
	like($journal_text, qr/"action":"delete"/, 'deletions are journaled');

	# Master-side delete goes to the client trash.
	unlink $env->server_path('a.txt');
	my $remote_delete = $env->sync();
	is($remote_delete->{summary}{deleted}, 1, 'master deletion propagated');
	ok(!$env->exists_in('client', 'a.txt'), 'client file removed');
	my @client_trash = glob(File::Spec->catfile($env->{home}, 'trash', 'repos', 'docs', '*', '*', '*', 'a.txt'));
	ok(@client_trash, 'client deletion is in the client trash');
}

# ------------------------------------------------- delete versus modification
{
	my $env = TestSync->new_env();

	$env->write_file('client', 'kept.txt', "original\n", $T0);
	$env->write_file('client', 'gone.txt', "original\n", $T0);
	$env->sync();

	# Client deletes gone.txt, the master modifies it: the modification wins.
	unlink $env->client_path('gone.txt');
	$env->write_file('server', 'gone.txt', "edited on the server\n", $T0 + 100);

	my $resurrect = $env->sync();
	is($resurrect->{summary}{pulled}, 1, 'master edit resurrects a client-deleted file');
	is($env->read_file('client', 'gone.txt'), "edited on the server\n", 'client got the new content');
	is($resurrect->{exit}, 3, 'the run reports a warning');
	like(join(' ', @{ $resurrect->{warnings} }), qr/deleted on test-1/, 'warning explains what happened');

	# Master deletes kept.txt while the client edits it: the edit wins.
	unlink $env->server_path('kept.txt');
	$env->write_file('client', 'kept.txt', "edited on the client\n", $T0 + 200);

	my $push = $env->sync();
	is($push->{summary}{pushed}, 1, 'client edit resurrects a master-deleted file');
	is($env->read_file('server', 'kept.txt'), "edited on the client\n", 'master got the new content');
	is($push->{exit}, 3, 'the run reports a warning');
}

# ---------------------------------------------------------------- conflicts
{
	my $env = TestSync->new_env();

	$env->write_file('client', 'f.txt', "base\n", $T0);
	$env->sync();

	$env->write_file('client', 'f.txt', "client version\n", $T0 + 100);
	$env->write_file('server', 'f.txt', "master version\n", $T0 + 200);

	my $conflict = $env->sync();
	is($conflict->{summary}{conflicts}, 1, 'one conflict reported');
	is($conflict->{exit}, 3, 'conflicts exit 3');
	is($env->read_file('client', 'f.txt'), "master version\n", 'newer master version won');
	is($env->read_file('server', 'f.txt'), "master version\n", 'master unchanged');

	my @copies = grep { /\Af\.conflict-test-1-\d{8}T\d{6}Z(-\d+)?\.txt\z/ } @{ $env->tree($env->{client}) };
	is(scalar @copies, 1, 'the losing client version was preserved beside the winner');
	is($env->read_file('client', $copies[0]), "client version\n", 'conflict copy holds the losing content');

	# The conflict copy propagates on the next run, then everything is stable.
	my $propagate = $env->sync();
	is($propagate->{summary}{pushed}, 1, 'the conflict copy is pushed on the next run');
	ok($env->exists_in('server', $copies[0]), 'master now holds the conflict copy');

	my $stable = $env->sync();
	is($stable->{summary}{pushed}, 0, 'nothing left to push');
	is($stable->{summary}{pulled}, 0, 'nothing left to pull');
	is($stable->{summary}{conflicts}, 0, 'no repeated conflict');

	# Newer client content wins, and the master's old version is kept.
	$env->write_file('client', 'f.txt', "client wins\n", $T0 + 900);
	$env->write_file('server', 'f.txt', "master loses\n", $T0 + 800);
	my $client_wins = $env->sync();
	is($env->read_file('server', 'f.txt'), "client wins\n", 'newer client version won');
	is($env->read_file('client', 'f.txt'), "client wins\n", 'client keeps its version');
	my @server_copies = grep { /\Af\.conflict-test-1-\d{8}T\d{6}Z(-\d+)?\.txt\z/ }
		@{ $env->tree(File::Spec->catdir($env->{server}, 'master', 'docs')) };
	ok(scalar @server_copies >= 1, 'losing master version kept as a conflict copy in the master');

	my ($master_loser) = grep { $env->read_file('server', $_) eq "master loses\n" } @server_copies;
	ok($master_loser, 'losing master content preserved');
	$server_copies[0] = $master_loser if $master_loser;

	my $after = $env->sync();
	is($after->{summary}{pulled}, 1, 'client pulls the master conflict copy');
	ok($env->exists_in('client', $server_copies[0]), 'client has the conflict copy too');
}

# ------------------------------------------------------------------ dry run
{
	my $env = TestSync->new_env();

	$env->write_file('client', 'a.txt', "alpha\n", $T0);
	$env->write_file('client', 'b.txt', "beta\n", $T0);
	$env->sync();

	$env->write_file('client', 'a.txt', "alpha changed\n", $T0 + 50);
	unlink $env->client_path('b.txt');
	$env->write_file('client', 'c.txt', "new\n", $T0 + 60);

	my $server_before = $env->snapshot(File::Spec->catdir($env->{server}, 'master', 'docs'));
	my $base_before = $env->snapshot(File::Spec->catdir($env->{server}, '.filesync', 'repos', 'docs'));
	my $cache_path = File::Spec->catfile($env->{home}, 'cache', 'docs.json');
	my $cache_before = -e $cache_path ? App::FileSync::read_text($cache_path) : '';

	my $dry = $env->sync(dry_run => 1);
	ok($dry->{dry_run}, 'result is marked as a dry run');
	is(scalar @{ $dry->{actions} }, 3, 'dry run reports the three pending actions');

	is_deeply($env->snapshot(File::Spec->catdir($env->{server}, 'master', 'docs')), $server_before,
		'dry run did not touch the master');
	is_deeply($env->snapshot(File::Spec->catdir($env->{server}, '.filesync', 'repos', 'docs')), $base_before,
		'dry run did not touch the server state');
	is(App::FileSync::read_text($cache_path), $cache_before, 'dry run did not touch the client cache');
	is($env->read_file('client', 'a.txt'), "alpha changed\n", 'dry run did not touch the client');

	my $real = $env->sync();
	is($real->{summary}{pushed}, 2, 'the real run then pushes the modified and new file');
	is($real->{summary}{deleted}, 1, 'and deletes the removed file');
}

# ----------------------------------------------------------- deletion guard
{
	my $env = TestSync->new_env(max_deletes => 5);

	for my $i (1 .. 10) {
		$env->write_file('client', "file$i.txt", "content $i\n", $T0 + $i);
	}
	$env->sync();

	unlink $env->client_path('file' . $_ . '.txt') for 1 .. 6;

	my $error;
	eval { $env->sync(); 1 } or $error = $@;
	ok($error, 'bulk deletion is refused');
	like($error, qr/refusing to delete 6/, 'the refusal names the count');
	ok($env->exists_in('server', 'file1.txt'), 'the master was not touched');

	my $forced = $env->sync(force => 1);
	is($forced->{summary}{deleted}, 6, '--force performs the deletions');
	ok(!$env->exists_in('server', 'file1.txt'), 'files are gone after --force');
}

# The percentage guard is not replica-only: a normal client with a surviving
# base may delete exactly its share.  Two of twenty files is the 10% allowance.
{
	my $env = TestSync->new_env();

	$env->write_file('client', sprintf('file%02d.txt', $_), "content $_\n", $T0 + $_)
		for 1 .. 20;
	is($env->sync()->{summary}{pushed}, 20, 'the client pushes twenty files');

	my $base_path = $env->meta_path('clients', 'test-1.json');
	my $base = App::FileSync::json_decode(App::FileSync::read_text($base_path));
	is(scalar(keys %{ $base->{entries} }), 20, 'the base survives with twenty entries');

	unlink $env->client_path('file19.txt');
	unlink $env->client_path('file20.txt');

	my $allowed = $env->sync();
	is($allowed->{summary}{deleted}, 2,
		'a local deletion within the percentage limit proceeds without --force');
	is($allowed->{summary}{pushed}, 0, 'nothing else is pushed');
	is($allowed->{summary}{pulled}, 0, 'nothing is pulled');
	is($allowed->{exit}, 0, 'the allowed deletion exits 0');

	ok(!$env->exists_in('server', 'file19.txt'), 'the first deletion reached the master');
	ok(!$env->exists_in('server', 'file20.txt'), 'the second deletion reached the master');
	ok($env->exists_in('server', 'file18.txt'), 'files inside the allowance stay');
	is($env->read_file('server', 'file18.txt'), "content 18\n", 'with their content');

	$base = App::FileSync::json_decode(App::FileSync::read_text($base_path));
	is(scalar(keys %{ $base->{entries} }), 18,
		'the base advanced to the eighteen survivors');

	my $stable = $env->sync();
	is($stable->{summary}{deleted}, 0, 'the allowed deletion is not repeated');
	is($stable->{summary}{pushed}, 0, 'nothing is left to push');
	is($stable->{summary}{pulled}, 0, 'and nothing is left to pull');
}

# One more local deletion than the allowance is refused before the master is
# touched, even though the client has already removed the files from its tree.
{
	my $env = TestSync->new_env();

	$env->write_file('client', sprintf('file%02d.txt', $_), "content $_\n", $T0 + $_)
		for 1 .. 20;
	is($env->sync()->{summary}{pushed}, 20, 'the client pushes twenty files');

	my $base_path = $env->meta_path('clients', 'test-1.json');
	my $base_before = App::FileSync::read_text($base_path);
	my $cache_path = File::Spec->catfile($env->{home}, 'cache', 'docs.json');
	my $cache_before = App::FileSync::read_text($cache_path);
	my $master_before = $env->snapshot(File::Spec->catdir($env->{server}, 'master', 'docs'));

	unlink $env->client_path('file18.txt');
	unlink $env->client_path('file19.txt');
	unlink $env->client_path('file20.txt');

	my $error;
	eval { $env->sync(); 1 } or $error = $@;
	ok($error, 'three local deletions are refused without --force');
	like($error, qr/refusing to delete 3 of 20 known files \(limit is 10%\)/,
		'the refusal names the count, the surviving base and the percentage');

	is_deeply($env->snapshot(File::Spec->catdir($env->{server}, 'master', 'docs')),
		$master_before, 'the refused run leaves the master untouched');
	is(App::FileSync::read_text($base_path), $base_before,
		'the refusal does not advance the stored base');
	is(App::FileSync::read_text($cache_path), $cache_before,
		'and does not advance the client cache');

	my $base = App::FileSync::json_decode(App::FileSync::read_text($base_path));
	is(scalar(keys %{ $base->{entries} }), 20, 'the base still knows all twenty files');
	ok($env->exists_in('server', 'file20.txt'), 'the last master copy is still there');
	is($env->read_file('server', 'file18.txt'), "content 18\n", 'and keeps its content');

	my $forced = $env->sync(force => 1);
	is($forced->{summary}{deleted}, 3, '--force performs the three deletions');
	is($forced->{summary}{pushed}, 0, 'nothing else is pushed');
	is($forced->{summary}{pulled}, 0, 'nothing is pulled');
	ok(!$env->exists_in('server', 'file20.txt'), 'the forced deletions reach the master');
	is_deeply([ @{ $env->tree(File::Spec->catdir($env->{server}, 'master', 'docs')) } ],
		[ map { sprintf 'file%02d.txt', $_ } 1 .. 17 ],
		'the master keeps exactly the seventeen files the client kept');

	my $stable = $env->sync();
	is($stable->{summary}{deleted}, 0, 'nothing is left to delete after --force');
	is($stable->{summary}{pushed}, 0, 'and nothing is left to push');
	is($stable->{summary}{pulled}, 0, 'and nothing is left to pull');
}

# The same guard covers master-to-client deletions: a normal client with a
# surviving base may lose exactly its share when the master removes files.
{
	my $env = TestSync->new_env();

	$env->write_file('client', sprintf('file%02d.txt', $_), "content $_\n", $T0 + $_)
		for 1 .. 20;
	is($env->sync()->{summary}{pushed}, 20, 'the client pushes twenty files');

	my $base_path = $env->meta_path('clients', 'test-1.json');
	my $base = App::FileSync::json_decode(App::FileSync::read_text($base_path));
	is(scalar(keys %{ $base->{entries} }), 20, 'the base survives with twenty entries');

	unlink $env->server_path('file19.txt');
	unlink $env->server_path('file20.txt');

	my $allowed = $env->sync();
	is($allowed->{summary}{deleted}, 2,
		'a master deletion within the percentage limit proceeds without --force');
	is($allowed->{summary}{pulled}, 0, 'nothing is pulled');
	is($allowed->{summary}{pushed}, 0, 'nothing is pushed');
	is($allowed->{exit}, 0, 'the allowed master deletion exits 0');

	ok(!$env->exists_in('client', 'file19.txt'), 'the first master deletion reached the client');
	ok(!$env->exists_in('client', 'file20.txt'), 'the second master deletion reached the client');
	ok($env->exists_in('client', 'file18.txt'), 'files inside the allowance stay locally');
	is($env->read_file('client', 'file18.txt'), "content 18\n", 'with their content');

	my @trash = glob(File::Spec->catfile(
		$env->{home}, 'trash', 'repos', 'docs', '*', '*', '*', 'file19.txt'));
	ok(@trash, 'the copy removed by the master went to the client trash');

	$base = App::FileSync::json_decode(App::FileSync::read_text($base_path));
	is(scalar(keys %{ $base->{entries} }), 18,
		'the base advanced to the eighteen survivors');

	my $stable = $env->sync();
	is($stable->{summary}{deleted}, 0, 'the allowed master deletion is not repeated');
	is($stable->{summary}{pulled}, 0, 'nothing is left to pull');
	is($stable->{summary}{pushed}, 0, 'and nothing is left to push');
}

# One more master deletion than the allowance is refused before the client
# removes anything; both sides still agree with the surviving base.
{
	my $env = TestSync->new_env();

	$env->write_file('client', sprintf('file%02d.txt', $_), "content $_\n", $T0 + $_)
		for 1 .. 20;
	is($env->sync()->{summary}{pushed}, 20, 'the client pushes twenty files');

	my $base_path = $env->meta_path('clients', 'test-1.json');
	my $base_before = App::FileSync::read_text($base_path);
	my $cache_path = File::Spec->catfile($env->{home}, 'cache', 'docs.json');
	my $cache_before = App::FileSync::read_text($cache_path);
	my $client_before = $env->snapshot($env->{client});

	unlink $env->server_path('file18.txt');
	unlink $env->server_path('file19.txt');
	unlink $env->server_path('file20.txt');
	my $master_after = $env->snapshot(File::Spec->catdir($env->{server}, 'master', 'docs'));

	my $error;
	eval { $env->sync(); 1 } or $error = $@;
	ok($error, 'three master deletions are refused without --force');
	like($error, qr/refusing to delete 3 of 20 known files \(limit is 10%\)/,
		'the refusal names the count, the surviving base and the percentage');

	is_deeply($env->snapshot($env->{client}), $client_before,
		'the refused run leaves every client file untouched');
	is(App::FileSync::read_text($cache_path), $cache_before,
		'and does not advance the client cache');
	is(App::FileSync::read_text($base_path), $base_before,
		'nor the stored base');
	is_deeply($env->snapshot(File::Spec->catdir($env->{server}, 'master', 'docs')),
		$master_after, 'the refusal does not touch the master either');

	my $base = App::FileSync::json_decode(App::FileSync::read_text($base_path));
	is(scalar(keys %{ $base->{entries} }), 20, 'the base still knows all twenty files');
	ok($env->exists_in('client', 'file20.txt'), 'the last local copy is still there');
	is($env->read_file('client', 'file18.txt'), "content 18\n", 'and keeps its content');
	ok(!$env->exists_in('server', 'file20.txt'), 'the master deletions are real');

	my $forced = $env->sync(force => 1);
	is($forced->{summary}{deleted}, 3, '--force performs the three deletions');
	is($forced->{summary}{pulled}, 0, 'nothing else is pulled');
	is($forced->{summary}{pushed}, 0, 'nothing is pushed');
	ok(!$env->exists_in('client', 'file20.txt'), 'the forced deletions reach the client');
	is_deeply([ @{ $env->tree($env->{client}) } ],
		[ '.filesync-root', map { sprintf 'file%02d.txt', $_ } 1 .. 17 ],
		'the client keeps exactly the seventeen surviving files');

	my $stable = $env->sync();
	is($stable->{summary}{deleted}, 0, 'nothing is left to delete after --force');
	is($stable->{summary}{pulled}, 0, 'and nothing is left to pull');
	is($stable->{summary}{pushed}, 0, 'and nothing is left to push');
}

# ------------------------------------------------------------ safety rails
{
	my $env = TestSync->new_env();
	$env->write_file('client', 'a.txt', "alpha\n", $T0);
	$env->sync();

	unlink File::Spec->catfile($env->{client}, '.filesync-root');
	throws_ok { $env->sync() } qr/marker/, 'a missing marker stops the run';
}

{
	my $env = TestSync->new_env();
	$env->write_file('client', 'a.txt', "alpha\n", $T0);

	my $lock = App::FileSync::Lock::acquire(
		path => File::Spec->catfile($env->{home}, 'locks', 'docs.lock'),
		nonblock => 1,
	);
	ok($lock, 'test holds the client lock');

	my $result = $env->sync();
	is($result->{exit}, 2, 'a second run reports the lock');
	ok(!$env->exists_in('server', 'a.txt'), 'the locked run did nothing');

	undef $lock;
	my $after = $env->sync();
	is($after->{summary}{pushed}, 1, 'the sync works once the lock is released');
}

# ------------------------------------------------------- awkward file names
{
	my $env = TestSync->new_env();

	my $name = "h\xc3\xa9llo w\xc3\xb6rld.txt";
	# Windows forbids a double quote in a filename; an ampersand is still a
	# shell metacharacter, so the quoting path is exercised there too.
	my $quoted = $^O eq 'MSWin32'
		? q{quote'and&double.txt}
		: q{quote'and"double.txt};
	$env->write_file('client', $name, "unicode\n", $T0);
	$env->write_file('client', 'with space.txt', "spaces\n", $T0);
	$env->write_file('client', $quoted, "quotes\n", $T0);

	my $result = $env->sync();
	is($result->{summary}{pushed}, 3, 'awkward names are pushed');
	ok($env->exists_in('server', $name), 'UTF-8 name survived the protocol');
	is($env->read_file('server', $name), "unicode\n", 'UTF-8 content survived');
	ok($env->exists_in('server', 'with space.txt'), 'spaces survived');
	ok($env->exists_in('server', $quoted), 'quotes and metacharacters survived');

	my $again = $env->sync();
	is($again->{summary}{pushed}, 0, 'no re-push of awkward names');
}

# --------------------------------------------------------------- large file
{
	my $env = TestSync->new_env();

	my $big = join '', map { chr(($_ * 37) % 256) } 1 .. 700_000;
	$env->write_file('client', 'big.bin', $big, $T0);

	my $result = $env->sync();
	is($result->{summary}{pushed}, 1, 'large file pushed');

	open my $in, '<', $env->server_path('big.bin') or die $!;
	binmode $in;
	local $/;
	my $copied = <$in>;
	close $in;

	is(length($copied), length($big), 'large file size matches');
	is($copied, $big, 'large file content matches across chunks');
}

done_testing();
