
use strict;
use warnings;

use Test::More
    tests => 1
;

use CSS::Orientation;

my $input = 'background:url(rtl.png)';
my $output = 'background:url(ltr.png)';
my $result = CSS::Orientation::FixLtrAndRtlInUrl( $input );

is( $output, $result );

