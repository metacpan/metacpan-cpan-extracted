#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
 
plan tests => 1;
 
BEGIN {
    use_ok( 'DBIx::Core::Handle::ReturnValue' ) || print "Bail out!\n";
}
 
diag( "Testing DBIx::Core::Handle::ReturnValue $DBIx::Core::Handle::ReturnValue::VERSION, Perl $], $^X" );