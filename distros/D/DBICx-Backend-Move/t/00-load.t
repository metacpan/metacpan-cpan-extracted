#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'DBICx::Backend::Move::SQLite' ) || print "Bail out!\n";
    use_ok( 'DBICx::Backend::Move::Psql' )   || print "Bail out!\n";
    use_ok( 'App::DBICx::Backend::Move' )    || print "Bail out!\n";
}

diag( "Testing DBICx::Backend::Move $DBICx::Backend::Move::VERSION, Perl $], $^X" );
