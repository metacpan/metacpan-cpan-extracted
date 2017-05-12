#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::BlackBox' ) || print "Bail out!
";
}

diag( "Testing DBIx::BlackBox $DBIx::BlackBox::VERSION, Perl $], $^X" );
