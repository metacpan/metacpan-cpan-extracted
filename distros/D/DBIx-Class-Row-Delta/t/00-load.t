#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::Row::Delta' ) || print "Bail out!
";
}

diag( "Testing DBIx::Class::Row::Delta $DBIx::Class::Row::Delta::VERSION, Perl $], $^X" );
