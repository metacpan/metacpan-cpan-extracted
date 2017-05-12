use strict;
use warnings;

use Test::More tests => 3;

use Archive::Ar::Libarchive qw(GNU);

my $content = do {local $/ = undef; <DATA>};

my $ar = Archive::Ar::Libarchive->new();
ok $ar->read_memory($content) or diag $ar->error;
is $ar->type, GNU;

my $regurg = $ar->write;
is $regurg, $content;

__DATA__
!<arch>
//                                              22        `
verylongfilename.txt/
foo.txt/        1396584498  1000  1000  100644  16        `
contents of foo
/0              1396584491  1000  1000  100644  29        `
contents of verylongfilename

