
use strict;
use warnings;

use Test::More
    tests => 4
;

use CSS::Orientation qw( );

my @input = qw[ 1px 2px 3px 4px ];
my $output = '2px 1px 4px 3px';
my $result = CSS::Orientation::ReorderBorderRadiusPart( @input );

is( $result, $output, 'with 4 arguments' );

# 3 arguments
@input = qw[ 1px 2px 3px ];
$output = '2px 1px 2px 3px';
$result = CSS::Orientation::ReorderBorderRadiusPart( @input );

is( $result, $output, 'with 3 arguments' );

# 2 arguments
@input = qw[ 1px 2px ];
$output = '2px 1px';
$result = CSS::Orientation::ReorderBorderRadiusPart( @input );

is( $result, $output, 'with 2 arguments' );

# 1 argument
@input = qw[ 1px ];
$output = '1px';
$result = CSS::Orientation::ReorderBorderRadiusPart( @input );

is( $result, $output, 'with 1 argument' );

