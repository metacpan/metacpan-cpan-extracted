#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::Objects' ) || print "Bail out!\n";
}

#diag( "Testing DBIx::Class::Objects $DBIx::Class::Objects::VERSION, Perl $], $^X" );
