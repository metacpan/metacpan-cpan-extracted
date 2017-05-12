use Test::More tests => 2;

use strict;
use warnings;

use_ok( 'Business::RU' );

is Business::RU -> VERSION(), '0.2'
    => 'compare version';