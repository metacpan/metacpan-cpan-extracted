
use strict;
use warnings;

use Test::More
    tests => 1
;

use CSS::Orientation;

my $input = 'background:url(right.png)';
my $output = 'background:url(left.png)';
my $result = CSS::Orientation::FixLeftAndRightInUrl( $input );

is( $output, $result );

