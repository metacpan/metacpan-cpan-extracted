#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::LookupColumn::LookupColumnComponent' ) || print "Bail out!\n";
}

diag( "Testing DBIx::Class::LookupColumn::LookupColumnComponent $DBIx::Class::LookupColumn::LookupColumnComponent::VERSION, Perl $], $^X" );
