
use strict;
use warnings;

use Test::More tests => 2;

# ABSTRACT: Make sure things go bang!

use CPAN::Changes::Dependencies::Details;

is( eval { CPAN::Changes::Dependencies::Details->load;        1 }, undef, 'load explodes' );
is( eval { CPAN::Changes::Dependencies::Details->load_string; 1 }, undef, 'load_string explodes' );
