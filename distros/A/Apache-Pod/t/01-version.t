#!perl -T

use Test::More tests=>5;
use strict;

BEGIN {
    use_ok( 'Apache::Pod' );
    use_ok( 'Apache::Pod::HTML' );
    use_ok( 'Apache::Pod::Text' );
}

is( $Apache::Pod::VERSION, $Apache::Pod::HTML::VERSION, 'A::P::HTML matches' );
is( $Apache::Pod::VERSION, $Apache::Pod::Text::VERSION, 'A::P::Text matches' );

