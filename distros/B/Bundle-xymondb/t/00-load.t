#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bundle::xymondb' );
}

diag( "Testing Bundle::xymondb $Bundle::xymondb::VERSION, Perl $], $^X" );
