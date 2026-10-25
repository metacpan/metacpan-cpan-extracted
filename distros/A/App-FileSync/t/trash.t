use strict;
use warnings;
use Test::Most;

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

done_testing();
