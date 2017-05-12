use strict;
use warnings;
use Test::More tests => 3;
use Archive::Ar::Libarchive qw(COMMON);

my $content = do {local $/ = undef; <DATA>};

my $ar = Archive::Ar::Libarchive->new();
$ar->set_opt(warn => 1);
ok $ar->read_memory($content) or diag $ar->error;
is $ar->type, COMMON;

$ar->rename('verylongfilenam' => 'verylongfilename.txt');

my $regurg = $ar->write;
is $regurg, $content;

__DATA__
!<arch>
foo.txt/        1396584498  1000  1000  100644  16        `
contents of foo
verylongfilenam/1396584491  1000  1000  100644  29        `
contents of verylongfilename

