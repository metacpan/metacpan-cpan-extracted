use strict;
use warnings;
use Test::More tests => 2;
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
ok $ar->chmod('foo.txt', 0100750), 'chmod';

is $ar->get_content('foo.txt')->{mode}, 0100750, 'mode is set';

__DATA__
!<arch>
foo.txt         1384344423  1000  1000  100644  9         `
hi there

bar.txt         1384344423  1000  1000  100750  31        `
this is the content of bar.txt

