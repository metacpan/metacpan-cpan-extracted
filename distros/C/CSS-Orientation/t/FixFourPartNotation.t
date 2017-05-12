
use strict;
use warnings;

use Test::More
    tests => 1
;

use CSS::Orientation;

my $input = 'padding: 1px 2px 3px 4px';
my $output = 'padding: 1px 4px 3px 2px';
my $result = CSS::Orientation::FixFourPartNotation( $input );

is( $output, $result );

