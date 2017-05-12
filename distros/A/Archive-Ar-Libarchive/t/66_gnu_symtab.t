use strict;
use warnings;

use Test::More tests => 7;

use Archive::Ar::Libarchive qw(GNU);

my $content = do {local $/ = undef; <DATA>};

my $ar = Archive::Ar::Libarchive->new();
ok $ar->read_memory($content) or diag $ar->error;
is $ar->type, GNU;
is_deeply scalar $ar->list_files, [qw(foo.txt verylongfilenam.txt)];
my $regurg = $ar->write;
isnt $regurg, $content;

$ar->set_opt('symbols', '_symtab');
ok $ar->read_memory($content) or diag $ar->error;
is_deeply scalar $ar->list_files, [qw(_symtab foo.txt verylongfilenam.txt)];
$regurg = $ar->write;
is $regurg, $content;

__DATA__
!<arch>
//                                              21        `
verylongfilenam.txt/

/               0           0     0     100000  16        `
iamasymboltable
foo.txt/        1396584498  1000  1000  100644  16        `
contents of foo
/0              1396584491  1000  1000  100644  28        `
contents of verylongfilenam
