use strict;
use warnings;
use Test::More;

use_ok 'Alien::Gimp';
ok eval { Alien::Gimp->Inline('C') }, 'Inline method returns true';
is $@, '', 'no exception';

done_testing;
