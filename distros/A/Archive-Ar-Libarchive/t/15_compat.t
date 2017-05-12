use strict;
use warnings;

use Test::More tests => 5;

use Archive::Ar::Libarchive;

my $ar;

can_ok 'Archive::Ar::Libarchive', 'DEBUG';

$ar = Archive::Ar::Libarchive->new();
is $ar->get_opt('warn'), 0, 'warn off by default';

$ar->DEBUG();
is $ar->get_opt('warn'), 1, 'DEBUG method sets warn';

eval { $ar = Archive::Ar::Libarchive->new(undef, 1) };
is $@, '', 'debug option to new';

is $ar->get_opt('warn'), 1, 'debug option to new sets warn';
