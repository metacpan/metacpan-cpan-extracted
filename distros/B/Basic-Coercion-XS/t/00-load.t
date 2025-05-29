#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Basic::Coercion::XS' ) || print "Bail out!\n";
}

diag( "Testing Basic::Coercion::XS $Basic::Coercion::XS::VERSION, Perl $], $^X" );
