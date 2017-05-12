use strict;
use warnings;
use Test::More tests => 4;
use Archive::Ar::Libarchive qw(GNU);

my $content = do {local $/ = undef; <DATA>};

my $ar = Archive::Ar::Libarchive->new();
ok $ar->read_memory($content) or diag $ar->error;

eval { $ar->clear };
is $@, '', 'clear';

is $ar->get_opt('type'), undef, 'type is reset';
is_deeply [$ar->list_files], [], 'file list is empty';

__DATA__
!<arch>
//                                              22        `
verylongfilename.txt/
foo.txt/        1396584498  1000  1000  100644  16        `
contents of foo
/0              1396584491  1000  1000  100644  29        `
contents of verylongfilename

