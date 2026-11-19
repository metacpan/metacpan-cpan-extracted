use strict;
use warnings;
use Test::Most;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use App::FileSync::Ignore;
use App::FileSync::Scan;

my $root = tempdir(CLEANUP => 1);
make_path(File::Spec->catdir($root, 'sub', 'deep'));
make_path(File::Spec->catdir($root, 'empty'));
make_path(File::Spec->catdir($root, 'ignored'));

_write(File::Spec->catfile($root, 'a.txt'), "alpha\n", 1_700_000_000);
_write(File::Spec->catfile($root, 'sub', 'b.bin'), "\x00\x01\x02\xff", 1_700_000_100);
_write(File::Spec->catfile($root, 'sub', 'deep', 'c.txt'), "gamma\n", 1_700_000_200);
_write(File::Spec->catfile($root, 'ignored', 'd.txt'), "delta\n", 1_700_000_300);

my $ignore = App::FileSync::Ignore->new(patterns => ['ignored']);
my $scan = App::FileSync::Scan::scan(root => $root, ignore => $ignore);
my ($manifest, $stats, $skipped) = @{$scan}{qw(manifest stats skipped)};
is(ref $scan, q{HASH}, q{scan returns one hashref rather than a list});

is_deeply([sort keys %{$manifest}], [qw(a.txt empty sub/b.bin sub/deep/c.txt)],
	'expected files and the empty directory are found, ignored tree is pruned');
is($manifest->{'empty'}{t}, 'd', 'empty directory recorded as a directory');
is($stats->{files}, 3, 'three files');
is($stats->{hashed}, 3, 'everything hashed on the first pass');
is($stats->{cached}, 0, 'no cache hits on the first pass');
is($stats->{dirs}, 1, 'one empty directory');
ok(!exists $manifest->{'ignored/d.txt'}, 'ignored file was not scanned');

is($manifest->{'a.txt'}{s}, 6, 'size recorded');
is($manifest->{'a.txt'}{m}, 1_700_000_000, 'mtime recorded');
like($manifest->{'a.txt'}{h}, qr/\A[0-9a-f]{64}\z/, 'sha256 recorded');

my ($second, $second_stats) = _parts(App::FileSync::Scan::scan(
	root => $root, ignore => $ignore, cache => $manifest,
));
is($second_stats->{hashed}, 0, 'second pass uses the stat cache');
is($second_stats->{cached}, 3, 'every file came from the cache');
is_deeply($second, $manifest, 'second manifest is identical');

# Same size, different mtime: must be rehashed.
_write(File::Spec->catfile($root, 'a.txt'), "beta!\n", 1_700_000_500);
my ($third, $third_stats) = _parts(App::FileSync::Scan::scan(
	root => $root, ignore => $ignore, cache => $manifest,
));
is($third_stats->{hashed}, 1, 'changed mtime forces a rehash');
isnt($third->{'a.txt'}{h}, $manifest->{'a.txt'}{h}, 'hash changed with the content');

# A missing root is reported, not fatal.
my ($missing, $missing_stats) = _parts(App::FileSync::Scan::scan(
	root => File::Spec->catdir($root, 'does-not-exist'),
));
is_deeply($missing, {}, 'missing root yields an empty manifest');
ok($missing_stats->{skipped} > 0, 'missing root is reported as skipped');

SKIP: {
	skip 'symlinks are not available here', 1
		unless eval { symlink(File::Spec->catfile($root, 'a.txt'), File::Spec->catfile($root, 'link.txt')) };

	my ($with_link, $link_stats) = _parts(App::FileSync::Scan::scan(root => $root, ignore => $ignore));
	ok(!exists $with_link->{'link.txt'}, 'symlinks are skipped');
	ok($link_stats->{skipped} >= 1, 'skipped symlink is reported');
	unlink File::Spec->catfile($root, 'link.txt');
}

sub _parts {
	my ($scan) = @_;
	return @{$scan}{qw(manifest stats skipped)};
}

sub _write {
	my ($path, $content, $mtime) = @_;
	open my $fh, '>', $path or die "Cannot write $path: $!";
	binmode $fh;
	print {$fh} $content;
	close $fh;
	utime($mtime, $mtime, $path);
}

# --- clean_stale_temps ---------------------------------------------------------

# A run that dies leaves .filesync-tmp-* files behind.  Those at least
# max_age old are removed anywhere under the root; younger ones may belong to
# a run in progress, and nothing else is touched.
{
	my $now = time;
	my $hour = 3_600;
	my $tree = tempdir(CLEANUP => 1);
	my $path = sub { File::Spec->catfile($tree, split m{/}, shift) };
	make_path($path->('sub/deep'), $path->('.filesync-tmp-dir'));

	my %files = (
		'.filesync-tmp-root'          => $now - 2 * $hour,	# stale, at the root
		'sub/deep/.filesync-tmp-deep' => $now - 2 * $hour,	# stale, nested
		'sub/.filesync-tmp-boundary'  => $now - $hour,	# exactly max_age: stale
		'sub/.filesync-tmp-young'     => $now - 60,	# a run may still own it
		'old.txt'                     => $now - 9 * $hour,	# not a temporary
		'sub/x.filesync-tmp-1'        => $now - 9 * $hour,	# the prefix is not at the start
		'.filesync-tmp-dir/inside'    => $now - 9 * $hour,	# a directory is not a temp file
	);
	_write($path->($_), "data\n", $files{$_}) for keys %files;

	is(App::FileSync::Scan::clean_stale_temps(root => $tree), 3, 'three stale temporaries are removed');
	ok(!-e $path->($_), "$_ is gone") for qw(.filesync-tmp-root sub/deep/.filesync-tmp-deep sub/.filesync-tmp-boundary);
	ok(-e $path->($_), "$_ is kept")
		for qw(sub/.filesync-tmp-young old.txt sub/x.filesync-tmp-1 .filesync-tmp-dir/inside);
	ok(-d $path->('.filesync-tmp-dir'), 'a directory with the prefix is kept');

	is(App::FileSync::Scan::clean_stale_temps(root => $tree), 0, 'a second pass finds nothing');
	is(App::FileSync::Scan::clean_stale_temps(root => $tree, max_age => 0), 1, 'max_age 0 takes the young one too');
	ok(!-e $path->('sub/.filesync-tmp-young'), 'which is then gone');

	is(App::FileSync::Scan::clean_stale_temps(root => $path->('missing')), 0, 'a missing root removes nothing');
	is(App::FileSync::Scan::clean_stale_temps(), 0, 'and so does no root');
}

# A symlinked directory is not followed out of the tree.
SKIP: {
	my $tree = tempdir(CLEANUP => 1);
	my $outside = tempdir(CLEANUP => 1);
	my $stale = File::Spec->catfile($outside, '.filesync-tmp-elsewhere');
	_write($stale, "data\n", time - 7_200);
	skip 'symlinks are not available here', 2
		unless eval { symlink $outside, File::Spec->catfile($tree, 'link') };

	is(App::FileSync::Scan::clean_stale_temps(root => $tree), 0, 'nothing is removed through a symlink');
	ok(-e $stale, 'the temporary outside the tree is untouched');
}

done_testing();
