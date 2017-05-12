#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Leaf::Walker' );
}

diag( "Testing Data::Leaf::Walker $Data::Leaf::Walker::VERSION, Perl $], $^X" );
