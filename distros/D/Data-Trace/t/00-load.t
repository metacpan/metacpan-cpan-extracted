#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Trace' ) || print "Bail out!\n";
}

diag( "Testing Data::Trace $Data::Trace::VERSION, Perl $], $^X" );
