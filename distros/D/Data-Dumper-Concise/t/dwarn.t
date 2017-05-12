use strict;
use warnings;

use Devel::Dwarn;

use Test::More qw(no_plan);

can_ok __PACKAGE__, qw{Dwarn DwarnS DwarnL DwarnN};

can_ok 'Devel::Dwarn', qw{Dwarn DwarnS DwarnL DwarnN};
ok($Dwarn, '$Dwarn gets exported');
ok($DwarnN, '$DwarnN gets exported');
