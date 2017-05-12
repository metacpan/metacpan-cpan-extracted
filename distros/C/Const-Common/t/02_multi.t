use strict;
use warnings;
use utf8;
use Test::More;

use t::Const2;

is( t::Const->FIRST,  1);
is SECOND, 2;
is MONTH->{JAN}, 1;
is( t::Const->const('FIRST'), 1 );
is BAR, 'BAZ';

done_testing;
