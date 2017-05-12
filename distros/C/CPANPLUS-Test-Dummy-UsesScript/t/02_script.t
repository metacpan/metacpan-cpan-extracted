use strict;
use warnings;
use Test::More tests => 1;

my $result = system('pdummydummy');
is( $result, 0, 'Result should be zero, mmmkay' );
