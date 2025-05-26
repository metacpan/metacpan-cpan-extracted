#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Basic::Types::XS' ) || print "Bail out!\n";
}

diag( "Testing Basic::Types::XS $Basic::Types::XS::VERSION, Perl $], $^X" );
