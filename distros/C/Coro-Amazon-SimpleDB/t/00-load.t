#!perl -T

use lib '..';
use Test::More tests => 1;

BEGIN {
    use_ok( 'Coro::Amazon::SimpleDB' ) || print "Bail out!
";
}

diag( "Testing Coro::Amazon::SimpleDB $Coro::Amazon::SimpleDB::VERSION, Perl $], $^X" );
