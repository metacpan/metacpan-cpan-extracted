use strict;
use warnings;
use Test::More tests => 8;
use File::Temp qw(tempdir);
use Cwd;

my $wd = cwd;
END { chdir $wd; }

use Archive::Ar::Libarchive;

my $dir = tempdir(CLEANUP => 1);
my $content = do {local $/ = undef; <DATA>};

umask 0;
my $ar  = Archive::Ar::Libarchive->new();
ok $ar->read_memory($content), 'read_memory' or diag $ar->error;
chdir $dir or die;
ok $ar->extract_file('foo.txt'), 'extract';
my @st = lstat 'foo.txt';
ok @st, 'stat';
SKIP: {
skip "premission mode not reliable on MSWin32", 1 if $^O eq 'MSWin32';
is $st[2], 0100644, 'mode 1 matches';
}
is $st[7], 9, 'size 1 matches';
SKIP: {
skip "mtime not reliable on MSWin32", 1 if $^O eq 'MSWin32';
is $st[9], 1384344423, 'mtime 1 matches';
}
if (open my $fd, 'foo.txt') {
    local $/ = undef;
    my $content = <$fd>;
    is $content, "hi there\n", 'content 1 matches';
}
else {
    fail "open 'foo.txt'";
}

ok !-e "bar.txt";

__DATA__
!<arch>
foo.txt         1384344423  1000  1000  100644  9         `
hi there

bar.txt         1384344423  1000  1000  100750  31        `
this is the content of bar.txt

