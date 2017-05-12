#!perl -T

use Test::More tests=>5;
use strict;

BEGIN {
    use_ok( 'Apache2::Pod' );
    use_ok( 'Apache2::Pod::HTML' );
    use_ok( 'Apache2::Pod::Text' );
}

is( $Apache2::Pod::VERSION, $Apache2::Pod::HTML::VERSION, 'A::P::HTML matches' );
is( $Apache2::Pod::VERSION, $Apache2::Pod::Text::VERSION, 'A::P::Text matches' );

