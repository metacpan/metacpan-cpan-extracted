use strict;
use warnings;
use Test::More;

use_ok 'Alien::Gimp';

ok -d(Alien::Gimp->gimpplugindir), 'plugindir exists';
ok -x(Alien::Gimp->gimptool), 'gimptool executable';
ok -x(Alien::Gimp->gimp), 'gimp executable';

done_testing;
