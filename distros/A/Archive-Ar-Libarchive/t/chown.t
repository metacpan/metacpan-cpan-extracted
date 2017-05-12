use strict;
use warnings;
use Test::More tests => 6;
use File::Temp qw(tempdir);
use Cwd;

my $wd = cwd;
END { chdir $wd; }

use Archive::Ar::Libarchive;

my $dir = tempdir(CLEANUP => 1);
my $content = do {local $/ = undef; <DATA>};

umask 0;
my $ar  = Archive::Ar::Libarchive->new();
$ar->read_memory($content) or diag $ar->error;

ok $ar->chown('foo.txt', 512), 'chown';
is $ar->get_content('foo.txt')->{uid}, 512,  'own is set';
is $ar->get_content('foo.txt')->{gid}, 1000, 'grp is unset';

ok $ar->chown('foo.txt', 750, 888), 'chown both uid and gid';
is $ar->get_content('foo.txt')->{uid}, 750,  'own is set';
is $ar->get_content('foo.txt')->{gid}, 888, 'grp is unset';


__DATA__
!<arch>
foo.txt         1384344423  1000  1000  100644  9         `
hi there

bar.txt         1384344423  1000  1000  100750  31        `
this is the content of bar.txt

