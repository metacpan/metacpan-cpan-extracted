use strict;
use warnings;
use Test::Most;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use App::FileSync::Trash;

my $root = tempdir(CLEANUP => 1);
my $source = tempdir(CLEANUP => 1);

my $file = File::Spec->catfile($source, 'a.txt');
open my $fh, '>', $file or die $!;
print {$fh} "content\n";
close $fh;

my $trash_root = File::Spec->catdir($root, 'trash');
my $now = 1_700_000_000;

my $moved = App::FileSync::Trash::move_to_trash(
	src   => $file,
	rel   => 'deep/a.txt',
	root  => $trash_root,
	epoch => $now,
);

ok($moved, 'move returned a destination');
ok(-e $moved, 'file now lives in the trash');
ok(!-e $file, 'file removed from its original place');
is($moved, File::Spec->catfile($trash_root, '2023', '11', '14', 'deep', 'a.txt'),
	'date-bucketed destination');
is(App::FileSync::Trash::date_of($moved), '2023-11-14',
	'a native path yields its date');
is(App::FileSync::Trash::date_of('C:\\trash\\2023\\11\\14\\a.txt'),
	'2023-11-14', 'a backslash path yields its date too');

open my $in, '<', $moved or die $!;
is(do { local $/; <$in> }, "content\n", 'content preserved');

# A second deletion of the same path on the same day must not overwrite the first.
open my $again, '>', $file or die $!;
print {$again} "second\n";
close $again;

my $second = App::FileSync::Trash::move_to_trash(
	src   => $file,
	rel   => 'deep/a.txt',
	root  => $trash_root,
	epoch => $now,
);
isnt($second, $moved, 'collision gets a distinct name');
is($second, "$moved.1", 'collision suffix is added');
ok(-e $moved, 'the first trashed copy survives');

# Versions are listed newest first.
my $versions = App::FileSync::Trash::versions(root => $trash_root, rel => 'deep/a.txt');
is(scalar @{$versions}, 2, 'both versions found');

# Pruning removes whole day buckets older than the retention period.
my $old = File::Spec->catdir($trash_root, '2023', '01', '01', 'ancient');
make_path($old);
open my $ancient, '>', File::Spec->catfile($old, 'x.txt') or die $!;
print {$ancient} "old\n";
close $ancient;

my $recent = File::Spec->catdir($trash_root, '2023', '11', '13', 'recent');
make_path($recent);
open my $fresh, '>', File::Spec->catfile($recent, 'y.txt') or die $!;
print {$fresh} "new\n";
close $fresh;

my $removed = App::FileSync::Trash::prune(
	root => $trash_root,
	days => 30,
	now  => $now,
);

my $old_bucket = File::Spec->catdir($trash_root, '2023', '01', '01');
ok((grep { $_ eq $old_bucket } @{$removed}), 'old bucket pruned');
ok(!-d File::Spec->catdir($trash_root, '2023', '01', '01'), 'old bucket removed from disk');
ok(-d File::Spec->catdir($trash_root, '2023', '11', '13'), 'recent bucket kept');

# A dry run reports without deleting.
my $dry = App::FileSync::Trash::prune(
	root    => $trash_root,
	days    => 0.0001,
	now     => $now,
	dry_run => 1,
);
ok(@{$dry}, 'dry run reports what it would remove');
ok(-d File::Spec->catdir($trash_root, '2023', '11', '13'), 'dry run deleted nothing');

# --- dated names ------------------------------------------------------------
#
# Trash buckets, snapshot dates, conflict-copy stamps and journal files are all
# named from the UTC date.  The names are on disk, so they must not change:
# zero-padded, UTC whatever the local zone, and past 2038.
{
	require App::FileSync;
	require App::FileSync::Snapshot;
	require App::FileSync::Store;

	my %cases = (
		0                 => [ '19700101T000000Z', '1970-01-01', [ '1970', '01', '01' ] ],
		86_399            => [ '19700101T235959Z', '1970-01-01', [ '1970', '01', '01' ] ],
		951_782_400       => [ '20000229T000000Z', '2000-02-29', [ '2000', '02', '29' ] ],
		1_700_000_000.75  => [ '20231114T221320Z', '2023-11-14', [ '2023', '11', '14' ] ],
		2_147_483_648     => [ '20380119T031408Z', '2038-01-19', [ '2038', '01', '19' ] ],
		4_102_444_800     => [ '21000101T000000Z', '2100-01-01', [ '2100', '01', '01' ] ],
	);

	local $ENV{TZ} = 'America/New_York';
	for my $epoch (sort { $a <=> $b } keys %cases) {
		my ($stamp, $date, $bucket) = @{ $cases{$epoch} };
		is(App::FileSync::format_utc($epoch), $stamp, "format_utc($epoch)");
		is(App::FileSync::Snapshot::date_for_epoch($epoch), $date, "date_for_epoch($epoch)");
		is(App::FileSync::Trash::_bucket('root', $epoch), File::Spec->catdir('root', @{$bucket}),
			"the trash bucket for $epoch is one directory per year, month and day");
	}

	my $store = App::FileSync::Store->new(root => tempdir(CLEANUP => 1), repo => 'docs', config => {});
	my @t = gmtime();
	is((File::Spec->splitpath($store->journal_path()))[2], sprintf('%04d-%02d.jsonl', $t[5] + 1900, $t[4] + 1),
		"the journal file is named after this UTC month");
}


# --- a directory into the trash ---------------------------------------------------

# A directory is renamed in one step, contents and all (the server trashes an
# empty directory a client deleted, and a directory a file replaces).
{
	my $from = tempdir(CLEANUP => 1);
	my $trash = File::Spec->catdir(tempdir(CLEANUP => 1), 'trash');
	my $put = sub {
		my ($rel, $content) = @_;
		my $path = File::Spec->catfile($from, split m{/}, $rel);
		make_path(dirname($path));
		open my $out, '>', $path or die "Cannot write $path: $!";
		print {$out} $content;
		close $out;
	};
	$put->('dir/one.txt', "one\n");
	$put->('dir/sub/two.txt', "two\n");
	make_path(File::Spec->catdir($from, 'dir', 'empty'));

	my $src = File::Spec->catdir($from, 'dir');
	my $where = App::FileSync::Trash::move_to_trash(src => $src, rel => 'docs/dir', root => $trash, epoch => $now);
	ok(!-e $src, 'the directory has left the tree');
	ok(-d $where, 'and is a directory in the trash');
	like($where, qr{\Q$trash\E.+docs.dir\z}, 'under its relative path in the day bucket');
	ok(-f File::Spec->catfile($where, 'sub', 'two.txt'), 'its nested files came with it');
	ok(-d File::Spec->catfile($where, 'empty'), 'and its empty subdirectory');

	# The same path trashed again that day is kept beside the first.
	make_path($src);
	my $again = App::FileSync::Trash::move_to_trash(src => $src, rel => 'docs/dir', root => $trash, epoch => $now);
	is($again, "$where.1", 'a second directory of the same name the same day gets .1');
	ok(-d $where && -d $again, 'both are kept');

	# A symlink to a directory is moved as a link; its target stays.
	SKIP: {
		my $target = File::Spec->catdir($from, 'target');
		make_path($target);
		my $link = File::Spec->catfile($from, 'link');
		skip 'symlinks are not available here', 3 unless eval { symlink $target, $link };
		my $moved_link = App::FileSync::Trash::move_to_trash(src => $link, rel => 'link', root => $trash, epoch => $now);
		ok(-l $moved_link, 'a symlink to a directory goes as a link');
		ok(!-e $link && !-l $link, 'and leaves the tree');
		ok(-d $target, 'its target is not moved');
	}

	throws_ok { App::FileSync::Trash::move_to_trash(src => $src, rel => 'gone', root => $trash, epoch => $now) }
		qr/\ACannot move \Q$src\E to /, 'a directory that is not there is trash.move';
}

done_testing();
