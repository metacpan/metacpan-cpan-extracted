use strict;
use warnings;
use Test::More;

use_ok 'Alien::Gimp';

ok -d(Alien::Gimp->gimpplugindir), 'plugindir exists' or diag Alien::Gimp->gimpplugindir;
ok -x(Alien::Gimp->gimptool), 'gimptool executable' or diag Alien::Gimp->gimptool;
ok -x(Alien::Gimp->gimp), 'gimp executable' or diag Alien::Gimp->gimp;

done_testing;
