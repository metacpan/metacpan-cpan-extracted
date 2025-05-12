use strict;
use warnings;
use Test::More;
use Contract::Declare;

use_ok('Contract::Declare');

can_ok('main', qw(contract interface method returns));

done_testing();