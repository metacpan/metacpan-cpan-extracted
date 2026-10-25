use strict;
use warnings;
use Test::Most;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);

use lib 't/lib';
use TestSync;
use App::FileSync;
use App::FileSync::Config;
use App::FileSync::Snapshot;

my $T0 = 1_700_000_000;
my $filesync = File::Spec->catfile($Bin, '..', 'bin', 'filesync');

sub write_file {
	my ($path, $content, $mtime) = @_;

	if ($path =~ m{\A(.*)/[^/]+\z} && !-d $1) {
		make_path($1);
	}

	open my $fh, '>', $path or die "Cannot write $path: $!";
	binmode $fh;
	print {$fh} $content;
	close $fh;

	utime($mtime, $mtime, $path) if defined $mtime;

	return $path;
}

# Replace a file the way the syncer does (temp + rename), which breaks any
# hardlink rather than writing through it.
sub replace_file {
	my ($path, $content, $mtime) = @_;

	my $temp = "$path.tmp-$$";
	open my $fh, '>', $temp or die "Cannot write $temp: $!";
	binmode $fh;
	print {$fh} $content;
	close $fh;

	utime($mtime, $mtime, $temp) if defined $mtime;
	rename($temp, $path) or die "Cannot rename $temp to $path: $!";

	return $path;
}

sub read_file {
	my ($path) = @_;
	open my $fh, '<', $path or die "Cannot read $path: $!";
	binmode $fh;
	local $/;
	my $content = <$fh>;
	close $fh;
	return $content;
}

# ------------------------------------------------------- the snapshot module
{
	my $root = tempdir(CLEANUP => 1);

	write_file("$root/a.txt", "alpha\n", $T0);
	write_file("$root/sub/b.txt", "bravo\n", $T0 + 1);
	write_file("$root/.filesync-root", "marker\n", $T0);
	make_path("$root/empty");

	# Hardlinks are the Unix default; Windows uses copies (SPEC 6.3).
	my $mode  = App::FileSync::Snapshot::default_mode();
	my $first = App::FileSync::Snapshot::create(
		root => $root, date => '2026-10-20', mode => $mode,
	);

	is($first->{created}, 1, 'a snapshot is created');
	is($first->{files}, 2, 'both files are in the snapshot');
	is($first->{linked}, $mode eq 'hardlink' ? 2 : 0,
		'files are hardlinked, not copied, when that is the platform default');
	is($first->{copied}, $mode eq 'copy' ? 2 : 0,
		'files are copied when copying is the platform default');
	SKIP: {
		skip 'inode numbers are not meaningful here', 1
			unless $mode eq 'hardlink' && $^O ne 'MSWin32';

		is((stat("$root/a.txt"))[1], (stat("$first->{path}/a.txt"))[1],
			'the snapshot file shares the inode with the mirror');
	}
	ok(-d "$first->{path}/empty", 'empty directories are captured');
	ok(!-e "$first->{path}/.filesync-root", 'the marker is not part of the snapshot');
	ok(!-e "$first->{path}/.filesync-snapshots", 'the snapshot directory does not contain itself');
	is(read_file("$first->{path}/sub/b.txt"), "bravo\n", 'content is captured');

	my $same = App::FileSync::Snapshot::create(
		root => $root, date => '2026-10-20', mode => $mode,
	);
	is($same->{created}, 0, 'an existing day is never overwritten');
	ok(-e "$first->{path}/a.txt", 'the first snapshot of the day survives');

	App::FileSync::Snapshot::create(root => $root, date => '2026-10-18');
	App::FileSync::Snapshot::create(root => $root, date => '2026-10-19');

	my $list = App::FileSync::Snapshot::list(root => $root);
	is_deeply(
		[ map { $_->{date} } @{$list} ],
		[ '2026-10-20', '2026-10-19', '2026-10-18' ],
		'list is newest first',
	);
	is($list->[0]{files}, 2, 'the listing counts files');

	my $pruned = App::FileSync::Snapshot::prune(root => $root, keep => 2);
	is_deeply($pruned->{removed}, ['2026-10-18'], 'the oldest snapshot is pruned');
	ok(!-d "$root/.filesync-snapshots/2026-10-18", 'it is gone from disk');
	is(scalar @{ App::FileSync::Snapshot::list(root => $root) }, 2, 'two snapshots are kept');

	# Restoring a single path replaces what is there now.
	replace_file("$root/a.txt", "corrupted\n", $T0 + 500);
	my $restored = App::FileSync::Snapshot::restore(
		root => $root, date => '2026-10-20', paths => ['a.txt'], to => $root,
	);
	is($restored->{files}, 1, 'one file restored');
	is(read_file("$root/a.txt"), "alpha\n", 'the old content is back');
	is((stat("$root/a.txt"))[9], $T0, 'mtime is preserved by the restore');

	# A copy-mode snapshot does not share inodes.
	my $copy = App::FileSync::Snapshot::create(
		root => $root, date => '2026-10-21', mode => 'copy',
	);
	is($copy->{copied}, 2, 'copy mode copies');
	SKIP: {
		skip 'inode numbers are not meaningful here', 1 if $^O eq 'MSWin32';

		isnt((stat("$root/a.txt"))[1], (stat("$copy->{path}/a.txt"))[1],
			'copy mode does not share inodes');
	}
	is(read_file("$copy->{path}/a.txt"), "alpha\n", 'copy mode captured the content');

	# A whole snapshot can be exported somewhere else.
	my $export = tempdir(CLEANUP => 1);
	my $whole = App::FileSync::Snapshot::restore(
		root => $root, date => '2026-10-20', to => $export,
	);
	is($whole->{files}, 2, 'the whole snapshot was restored');
	is(read_file("$export/sub/b.txt"), "bravo\n", 'nested content exported');
	ok(-d "$export/empty", 'empty directories are restored');

	# A hardlinked snapshot shares the inode, so an in-place edit of the mirror
	# is visible in it; copy mode is independent.  The syncer itself always
	# replaces files, so this only bites when something else edits the mirror.
	SKIP: {
		skip 'hardlinks are not the default here', 2
			unless App::FileSync::Snapshot::default_mode() eq 'hardlink';

		my $linked = App::FileSync::Snapshot::create(
			root => $root, date => '2026-10-22', mode => 'hardlink',
		);
		write_file("$root/a.txt", "edited in place\n", $T0 + 600);
		is(read_file("$linked->{path}/a.txt"), "edited in place\n",
			'in-place edits show through a hardlinked snapshot (documented caveat)');
		is(read_file("$copy->{path}/a.txt"), "alpha\n",
			'a copy-mode snapshot is unaffected by in-place edits');
	}
}

# ------------------------------------------- snapshots and the replica mirror
{
	my $env = TestSync->new_env(client_id => 'backup-1', role => 'replica');

	$env->write_file('server', 'a.txt', "master a\n", $T0);
	$env->write_file('server', 'sub/b.txt', "master b\n", $T0 + 1);
	$env->sync();

	my $snapshot = $env->snapshot_create();
	is($snapshot->{created}, 1, 'the replica takes a snapshot');
	is($snapshot->{files}, 2, 'the snapshot holds the mirrored files');
	ok(-e File::Spec->catfile($env->{client}, '.filesync-snapshots', $snapshot->{date}, 'a.txt'),
		'the snapshot lives inside the replica root');

	# A repo created before snapshots existed has no ignore entry for them; the
	# client must still keep the snapshot directory out of the manifest.
	my $config_path = App::FileSync::Config::repo_config_path($env->{server}, 'docs');
	my $config = App::FileSync::json_decode(App::FileSync::read_text($config_path));
	$config->{ignore} = [ grep { $_ ne '.filesync-snapshots' } @{ $config->{ignore} } ];
	App::FileSync::Config::save_repo($env->{server}, 'docs', $config);

	my $again = $env->sync();
	is($again->{summary}{deleted}, 0, 'the snapshot directory is not mistaken for a local extra');
	ok(-e File::Spec->catdir($env->{client}, '.filesync-snapshots', $snapshot->{date}),
		'the snapshot survives the next mirror run');

	# A damaged mirror can be rolled back from the snapshot.  The sync client
	# replaces files, so the hardlinked snapshot still holds the old bytes.
	replace_file($env->client_path('a.txt'), "corrupted\n", $T0 + 900);
	my $rollback = $env->snapshot_restore(date => $snapshot->{date}, path => 'a.txt');
	is($env->read_file('client', 'a.txt'), "master a\n", 'the snapshot restored the old content');
	ok($rollback->{into_root}, 'the restore went back into the replica root');

	is_deeply(
		[ map { $_->{date} } @{ $env->snapshot_list()->{snapshots} } ],
		[ $snapshot->{date} ],
		'the replica lists its snapshot',
	);
}

# ------------------------------------------------------------- command line
{
	my $env = TestSync->new_env(client_id => 'backup-1', role => 'replica');

	$env->write_file('server', 'a.txt', "master\n", $T0);
	$env->sync();

	App::FileSync::Snapshot::create(root => $env->{client}, date => '2026-01-01');
	App::FileSync::Snapshot::create(root => $env->{client}, date => '2026-01-02');

	my $output = `$^X $filesync snapshot --repo docs --keep 2 2>&1`;
	is($?, 0, 'filesync snapshot exits 0');
	like($output, qr/snapshot \d{4}-\d{2}-\d{2} taken \(1 file, 7 B\)/,
		'the snapshot reports its size');
	like($output, qr/pruned 1 old snapshot/, 'older snapshots are pruned');

	$output = `$^X $filesync snapshot list --repo docs 2>&1`;
	is($?, 0, 'filesync snapshot list exits 0');
	like($output, qr/2026-01-02/, 'a kept snapshot is listed');
	unlike($output, qr/2026-01-01/, 'the pruned snapshot is not listed');

	my $export = tempdir(CLEANUP => 1);
	$output = `$^X $filesync snapshot restore 2026-01-02 a.txt --repo docs --to $export 2>&1`;
	is($?, 0, 'filesync snapshot restore exits 0');
	is(read_file("$export/a.txt"), "master\n", 'the exported copy has the old content');

	$output = `$^X $filesync snapshot --repo docs --keep 2 2>&1`;
	is($?, 0, 'a second snapshot in the same day exits 0');
	like($output, qr/already exists/, 'and leaves the first one alone');
}

# A client must not pretend to be a replica.
{
	my $env = TestSync->new_env();
	$env->write_file('client', 'a.txt', "alpha\n", $T0);
	$env->sync();

	my $output = `$^X $filesync snapshot --repo docs 2>&1`;
	isnt($?, 0, 'snapshot on a client repo fails');
	like($output, qr/only a replica/, 'the error says snapshots are for replicas');
}

done_testing();
