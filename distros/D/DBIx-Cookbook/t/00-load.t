#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::Cookbook' ) || print "Bail out!
";
}

diag( "Testing DBIx::Cookbook $DBIx::Cookbook::VERSION, Perl $], $^X" );
