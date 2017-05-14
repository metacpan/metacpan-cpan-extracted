use strict;
use warnings;
use 5.010;

use Test::More tests => 2;

BEGIN {
    use_ok 'Boolean::String';
}

can_ok 'main', qw( true false );

