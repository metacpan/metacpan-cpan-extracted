#!/usr/bin/perl -w

use strict;
use Color::Similarity;
use Color::Similarity::Lab;
use Color::Similarity::RGB;

use Test::More tests => 9;

my $rgb = Color::Similarity->new( 'Color::Similarity::RGB' );
my $lab = Color::Similarity->new( 'Color::Similarity::Lab' );

is_deeply( $rgb->convert_rgb( 100, 120, 130 ), [ 100, 120, 130 ] );
is_deeply( [ map int( $_ ), @{$lab->convert_rgb( 100, 120, 130 )} ],
           [ 5000, -418, -677 ] );

is( $rgb->distance_rgb( [ 100, 120, 130 ], [ 100, 120, 130 ] ), 0 );
is( $lab->distance_rgb( [ 100, 120, 130 ], [ 100, 120, 130 ] ), 0 );

is( int( $rgb->distance_rgb( [ 200, 120, 130 ], [ 100, 120, 130 ] ) ), 100 );
is( int( $lab->distance_rgb( [ 200, 120, 130 ], [ 100, 120, 130 ] ) ), 3594 );

is( $rgb->distance_rgb( [ 200, 120, 130 ], [ 100, 120, 130 ] ),
    $rgb->distance( [ 200, 120, 130 ], [ 100, 120, 130 ] )
    );
is( $rgb->distance_rgb( [ 200, 120, 130 ], [ 100, 120, 130 ] ),
    $rgb->distance( map $rgb->convert_rgb( @$_ ),
                        [ 200, 120, 130 ], [ 100, 120, 130 ] )
    );
is( $lab->distance_rgb( [ 200, 120, 130 ], [ 100, 120, 130 ] ),
    $lab->distance( map $lab->convert_rgb( @$_ ),
                        [ 200, 120, 130 ], [ 100, 120, 130 ] )
    );
