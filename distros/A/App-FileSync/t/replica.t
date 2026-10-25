use strict;
use warnings;
use Test::Most;

use Digest::SHA ();
use File::Path qw(make_path);
use File::Spec;

use lib 't/lib';
use TestSync;
use App::FileSync::Protocol;
use App::FileSync::Transport::Local;

my $T0 = 1_700_000_000;

my $env = TestSync->new_env(client_id => 'backup-1', role => 'replica');

# Populate the master (an administrator can drop files in directly).
$env->write_file('server', 'a.txt', "master a\n", $T0);
$env->write_file('server', 'sub/b.txt', "master b\n", $T0 + 1);
make_path(File::Spec->catdir($env->{server}, 'master', 'docs', 'empty'));

my $first = $env->sync();
is($first->{summary}{pulled}, 3, 'replica pulls the files and the empty directory');
is($env->read_file('client', 'a.txt'), "master a\n", 'content mirrored');
ok($env->exists_in('client', 'sub/b.txt'), 'nested file mirrored');
ok($env->exists_in('client', 'empty'), 'empty directory mirrored');

my $again = $env->sync();
is($again->{summary}{pulled}, 0, 'nothing to do on a second run');

# A local edit is overwritten, not pushed.
$env->write_file('client', 'a.txt', "local edit\n", $T0 + 500);
my $overwrite = $env->sync();
is($overwrite->{summary}{pulled}, 1, 'local replica edit is pulled over');
is($overwrite->{summary}{pushed}, 0, 'replica never pushes');
is($env->read_file('client', 'a.txt'), "master a\n", 'master version restored on the replica');
is($env->read_file('server', 'a.txt'), "master a\n", 'master unchanged');
is($overwrite->{exit}, 3, 'the overwrite is reported as a warning');
like(join(' ', @{ $overwrite->{warnings} }), qr/changed on the replica/, 'warning explains the overwrite');

# A file that disappears from the master goes to the replica's trash.
unlink $env->server_path('sub/b.txt');
my $deleted = $env->sync();
is($deleted->{summary}{deleted}, 1, 'replica removes a file the master no longer has');
ok(!$env->exists_in('client', 'sub/b.txt'), 'replica file removed');
my @trash = glob(File::Spec->catfile($env->{home}, 'trash', 'repos', 'docs', '*', '*', '*', 'sub', 'b.txt'));
ok(@trash, 'removed replica file is in the local trash');
is(do { local $/; open my $fh, '<', $trash[0] or die $!; <$fh> }, "master b\n", 'trash preserves the content');

# A local extra file is removed as well.
$env->write_file('client', 'rogue.txt', "not on the master\n", $T0 + 600);
my $extra = $env->sync();
is($extra->{summary}{deleted}, 1, 'replica removes a local extra');
ok(!$env->exists_in('client', 'rogue.txt'), 'extra file removed');

# And the replica never pushes even when the master changes.
$env->write_file('server', 'a.txt', "master changed\n", $T0 + 700);
my $pull = $env->sync();
is($pull->{summary}{pulled}, 1, 'master changes reach the replica');
is($env->read_file('server', 'a.txt'), "master changed\n", 'master content untouched by the replica');

# A hostile or confused replica cannot write, even by talking the protocol
# directly: the plan it is given contains no write actions at all.
{
	my $env = TestSync->new_env(client_id => 'backup-2', role => 'replica');
	$env->write_file('server', 'a.txt', "master\n", $T0);

	my $transport = App::FileSync::Transport::Local->new(
		root   => $env->{server},
		repo   => 'docs',
		client => 'backup-2',
		role   => 'replica',
	);

	my $conn = App::FileSync::Protocol->new(
		in  => $transport->reader(),
		out => $transport->writer(),
	);

	$conn->send({
		cmd => 'hello', proto => 2, client => 'backup-2', host => 'test', os => $^O,
		role => 'replica', repo => 'docs', case_insensitive => 0, now => time,
	});
	ok($conn->recv()->{ok}, 'the replica session opens');

	my $content = "evil\n";
	my $sha = Digest::SHA->new(256);
	$sha->add($content);
	my $hash = $sha->hexdigest();

	$conn->send({
		cmd => 'manifest', part => 0, of => 1,
		entries => [
			{ p => 'evil.txt', t => 'f', s => length $content, m => $T0, h => $hash, mode => 0644 },
		],
	});
	ok($conn->recv()->{ok}, 'the manifest is accepted');

	$conn->send({ cmd => 'plan' });
	my $plan = $conn->recv();
	ok($plan->{ok}, 'a plan is produced');
	ok(!(grep { $_->{a} eq 'push' } @{ $plan->{actions} }),
		'a replica plan never contains a push');
	ok(!(grep { $_->{a} eq 'delete_remote' } @{ $plan->{actions} }),
		'a replica plan never deletes from the master');

	$conn->send({
		cmd => 'put', p => 'evil.txt', s => length $content, h => $hash,
		m => $T0, mode => 0644,
	});
	my $reply = $conn->recv();
	ok(!$reply->{ok}, 'the write is refused');
	like($reply->{error}, qr/not in the plan/, 'the refusal explains itself');
	ok(!$env->exists_in('server', 'evil.txt'), 'nothing was written to the master');

	$transport->close();
}

# A replica with a surviving base is stopped by the percentage deletion guard.
# The absolute limit is set far above the deletion count, so only the share of
# the base decides; with the base still present, that rule has a baseline.
{
	my $env = TestSync->new_env(
		client_id => 'backup-3', role => 'replica', max_deletes => 500,
	);

	$env->write_file('server', "file$_.txt", "master $_\n", $T0 + $_)
		for 1 .. 10;

	my $first = $env->sync();
	is($first->{summary}{pulled}, 10, 'the replica mirrors all ten master files');

	my $base = $env->meta_path('clients', 'backup-3.json');
	ok(-e $base, 'the replica keeps its base, so the percentage rule applies');
	my $base_before = do {
		local $/;
		open my $fh, '<', $base or die "Cannot read $base: $!";
		<$fh>;
	};

	# The master loses eight of its ten files.
	unlink $env->server_path("file$_.txt") for 3 .. 10;

	my $before = $env->snapshot($env->{client});

	my $error;
	eval { $env->sync(); 1 } or $error = $@;
	ok($error, 'the replica refuses the bulk deletion without --force');
	like($error, qr/refusing to delete 8 of 10 known files \(limit is 10%\)/,
		'the refusal names the count, the baseline and the percentage limit');

	is_deeply($env->snapshot($env->{client}), $before,
		'the refused mirror leaves every replica file untouched');
	ok($env->exists_in('client', 'file10.txt'),
		'even the last master-deleted file is still mirrored');
	is(do {
		local $/;
		open my $fh, '<', $base or die "Cannot read $base: $!";
		<$fh>;
	}, $base_before, 'the refusal does not advance the stored base');

	ok($env->exists_in('server', 'file1.txt'), 'the master still has the files it kept');
	ok(!$env->exists_in('server', 'file10.txt'), 'the master deletion is real');

	# --force is the documented escape hatch, and the mirror then converges.
	my $forced = $env->sync(force => 1);
	is($forced->{summary}{deleted}, 8, '--force removes the eight master-deleted files');
	is($forced->{summary}{pulled}, 0, 'nothing else needs pulling');
	is($forced->{summary}{pushed}, 0, 'the replica still pushes nothing');
	is_deeply(
		[ grep { $_ ne '.filesync-root' } @{ $env->tree($env->{client}) } ],
		[ 'file1.txt', 'file2.txt' ],
		'the replica mirrors exactly what the master kept',
	);
	is($env->read_file('client', 'file2.txt'), "master 2\n",
		'the surviving files keep their master content');

	my $stable = $env->sync();
	is($stable->{summary}{deleted}, 0, 'nothing is left to delete after --force');
	is($stable->{summary}{pulled}, 0, 'and nothing is left to pull');
	is($stable->{summary}{pushed}, 0, 'and the replica still pushes nothing');
}

# The same guard allows deletions up to the percentage limit.  Two of twenty
# files is exactly the 10% allowance, so this mirror converges without --force.
{
	my $env = TestSync->new_env(
		client_id => 'backup-4', role => 'replica', max_deletes => 500,
	);

	$env->write_file('server', sprintf('file%02d.txt', $_), "master $_\n", $T0 + $_)
		for 1 .. 20;

	my $first = $env->sync();
	is($first->{summary}{pulled}, 20, 'the replica mirrors twenty master files');

	# Deletions at the limit are allowed; only a larger share is refused.
	unlink $env->server_path('file19.txt');
	unlink $env->server_path('file20.txt');

	my $allowed = $env->sync();
	is($allowed->{summary}{deleted}, 2,
		'a deletion within the percentage limit proceeds without --force');
	is($allowed->{summary}{pulled}, 0, 'nothing else is transferred');
	is($allowed->{summary}{pushed}, 0, 'the replica still pushes nothing');

	is_deeply(
		[ grep { $_ ne '.filesync-root' } @{ $env->tree($env->{client}) } ],
		[ map { sprintf 'file%02d.txt', $_ } 1 .. 18 ],
		'the replica mirrors the eighteen files the master kept',
	);
	ok(!$env->exists_in('client', 'file19.txt'), 'the first deleted file is gone');
	ok(!$env->exists_in('client', 'file20.txt'), 'the second deleted file is gone');
	is($env->read_file('client', 'file18.txt'), "master 18\n",
		'the surviving files keep their master content');

	my @trash = glob(File::Spec->catfile(
		$env->{home}, 'trash', 'repos', 'docs', '*', '*', '*', 'file19.txt'));
	ok(@trash, 'the removed file went to the replica trash');

	my $stable = $env->sync();
	is($stable->{summary}{deleted}, 0, 'the allowed deletion is not repeated');
	is($stable->{summary}{pulled}, 0, 'nothing is left to pull');
	is($stable->{summary}{pushed}, 0, 'and nothing is pushed');
}

# One deletion over the allowance is refused: three of twenty is 15%, above
# the 10% limit, so the mirror must stay put until --force says otherwise.
{
	my $env = TestSync->new_env(
		client_id => 'backup-5', role => 'replica', max_deletes => 500,
	);

	$env->write_file('server', sprintf('file%02d.txt', $_), "master $_\n", $T0 + $_)
		for 1 .. 20;

	my $first = $env->sync();
	is($first->{summary}{pulled}, 20, 'the replica mirrors twenty master files');

	my $base = $env->meta_path('clients', 'backup-5.json');
	my $base_before = do {
		local $/;
		open my $fh, '<', $base or die "Cannot read $base: $!";
		<$fh>;
	};

	unlink $env->server_path('file18.txt');
	unlink $env->server_path('file19.txt');
	unlink $env->server_path('file20.txt');

	my $before = $env->snapshot($env->{client});

	my $error;
	eval { $env->sync(); 1 } or $error = $@;
	ok($error, 'one deletion over the allowance is refused without --force');
	like($error, qr/refusing to delete 3 of 20 known files \(limit is 10%\)/,
		'the refusal names three of twenty and the percentage');

	is_deeply($env->snapshot($env->{client}), $before,
		'the refused mirror leaves every replica file untouched');
	ok($env->exists_in('client', 'file20.txt'), 'the last deleted file is still mirrored');
	is(do {
		local $/;
		open my $fh, '<', $base or die "Cannot read $base: $!";
		<$fh>;
	}, $base_before, 'the refusal does not advance the stored base');

	ok($env->exists_in('server', 'file17.txt'), 'the master still has the files it kept');
	ok(!$env->exists_in('server', 'file18.txt'), 'the master deletions are real');

	my $forced = $env->sync(force => 1);
	is($forced->{summary}{deleted}, 3, '--force performs the three deletions');
	is($forced->{summary}{pulled}, 0, 'nothing else needs pulling');
	is($forced->{summary}{pushed}, 0, 'the replica still pushes nothing');
	is_deeply(
		[ grep { $_ ne '.filesync-root' } @{ $env->tree($env->{client}) } ],
		[ map { sprintf 'file%02d.txt', $_ } 1 .. 17 ],
		'the forced mirror matches the seventeen files the master kept',
	);
	is($env->read_file('client', 'file17.txt'), "master 17\n",
		'the surviving files keep their master content');

	my $stable = $env->sync();
	is($stable->{summary}{deleted}, 0, 'nothing is left to delete after --force');
	is($stable->{summary}{pulled}, 0, 'and nothing is left to pull');
	is($stable->{summary}{pushed}, 0, 'and the replica still pushes nothing');
}

done_testing();
