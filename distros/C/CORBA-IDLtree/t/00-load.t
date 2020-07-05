#!perl -T
use 5.008_003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CORBA::IDLtree' ) || print "Bail out!\n";
}

diag( "Testing CORBA::IDLtree $CORBA::IDLtree::VERSION, Perl $], $^X" );
