use strict;
use warnings;
use Test::More tests => 3;

ok( $] >= 5.006, "Your perl is new enough" );

use_ok('Class::Inspector');
use_ok('Class::Inspector::Functions');
