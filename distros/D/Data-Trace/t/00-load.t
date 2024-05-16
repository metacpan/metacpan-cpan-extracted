#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Data::Tie::Watch' ) || print "Bail out!\n";
    use_ok( 'Data::Trace'      ) || print "Bail out!\n";
}

diag( "Testing Data::Trace $Data::Trace::VERSION, Perl $], $^X" );
