#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::Result::ColumnData' ) || print "Bail out!
";
}

diag( "Testing DBIx::Class::Result::ColumnData $DBIx::Class::Result::ColumnData::VERSION, Perl $], $^X" );
