
use strict;
use warnings;

use Test::More
    tests => 1
;

use CSS::Orientation;

my $input = 'padding-left: 2px; margin-right: 1px;';
my $output = 'padding-right: 2px; margin-left: 1px;';
my $result = CSS::Orientation::FixLeftAndRight( $input );

is( $output, $result );

