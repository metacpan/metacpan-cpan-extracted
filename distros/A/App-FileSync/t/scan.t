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
my ($manifest, $stats, $skipped) = App::FileSync::Scan::scan(root => $root, ignore => $ignore);

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

my ($second, $second_stats) = App::FileSync::Scan::scan(
    root => $root, ignore => $ignore, cache => $manifest,
);
is($second_stats->{hashed}, 0, 'second pass uses the stat cache');
is($second_stats->{cached}, 3, 'every file came from the cache');
is_deeply($second, $manifest, 'second manifest is identical');

# Same size, different mtime: must be rehashed.
_write(File::Spec->catfile($root, 'a.txt'), "beta!\n", 1_700_000_500);
my ($third, $third_stats) = App::FileSync::Scan::scan(
    root => $root, ignore => $ignore, cache => $manifest,
);
is($third_stats->{hashed}, 1, 'changed mtime forces a rehash');
isnt($third->{'a.txt'}{h}, $manifest->{'a.txt'}{h}, 'hash changed with the content');

# A missing root is reported, not fatal.
my ($missing, $missing_stats) = App::FileSync::Scan::scan(
    root => File::Spec->catdir($root, 'does-not-exist'),
);
is_deeply($missing, {}, 'missing root yields an empty manifest');
ok($missing_stats->{skipped} > 0, 'missing root is reported as skipped');

SKIP: {
    skip 'symlinks are not available here', 1
        unless eval { symlink(File::Spec->catfile($root, 'a.txt'), File::Spec->catfile($root, 'link.txt')) };

    my ($with_link, $link_stats) = App::FileSync::Scan::scan(root => $root, ignore => $ignore);
    ok(!exists $with_link->{'link.txt'}, 'symlinks are skipped');
    ok($link_stats->{skipped} >= 1, 'skipped symlink is reported');
    unlink File::Spec->catfile($root, 'link.txt');
}

sub _write {
    my ($path, $content, $mtime) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    binmode $fh;
    print {$fh} $content;
    close $fh;
    utime($mtime, $mtime, $path);
}

done_testing();
