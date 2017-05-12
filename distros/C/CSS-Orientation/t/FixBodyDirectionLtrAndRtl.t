
use strict;
use warnings;

use Test::More
    tests => 1
;

use CSS::Orientation;

my $input = 'body { direction:ltr }';
my $output = 'body { direction:rtl }';
my $result = CSS::Orientation::FixBodyDirectionLtrAndRtl( $input );

is( $output, $result );

