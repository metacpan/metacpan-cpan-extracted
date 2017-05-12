#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dao::Map::Helper' ) || print "Bail out!
";
}

diag( "Testing Dao::Map::Helper $Dao::Map::Helper::VERSION, Perl $], $^X" );
