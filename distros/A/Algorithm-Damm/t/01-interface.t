use strict;
use warnings;

use Test::More tests => 1;

use Algorithm::Damm;

my @interface = qw(
    check_digit
    is_valid
);

can_ok( 'Algorithm::Damm', @interface );
