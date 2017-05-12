#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::Bulkmail' );
}

diag( "Testing App::Bulkmail $App::Bulkmail::VERSION, Perl $], $^X" );
