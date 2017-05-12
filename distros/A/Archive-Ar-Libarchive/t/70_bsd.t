use strict;
use warnings;

use Test::More tests => 3;

use Archive::Ar::Libarchive qw(BSD);

my $content = do {local $/ = undef; <DATA>};

my $ar = Archive::Ar::Libarchive->new();
ok $ar->read_memory($content) or diag $ar->error;
is $ar->type, BSD;
my $regurg = $ar->write;
is $regurg, $content;

__DATA__
!<arch>
foo.txt         1396073800  1000  1000  100644  16        `
contents of foo
#1/20           1396073800  1000  1000  100644  49        `
verylongfilename.txtcontents of verylongfilename

