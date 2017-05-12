#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Password::Simple' ) || print "Bail out!\n";
}

diag( "Testing Data::Password::Simple $Data::Password::Simple::VERSION, Perl $], $^X" );
