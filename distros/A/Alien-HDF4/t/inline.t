use strict;
use warnings;
use Test::More;

use_ok 'Alien::HDF4';
ok eval { Alien::HDF4->Inline('C') }, 'Inline method returns true';
is $@, '', 'no exception';

done_testing;
