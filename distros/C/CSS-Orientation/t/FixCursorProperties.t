
use strict;
use warnings;

use Test::More
    tests => 1
;

use CSS::Orientation;

my $input = 'cursor: ne-resize';
my $output = 'cursor: nw-resize';
my $result = CSS::Orientation::FixCursorProperties( $input );

is( $output, $result );

