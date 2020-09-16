#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Org::Template' ) || print "Bail out!\n";
}

diag( "Testing Data::Org::Template $Data::Org::Template::VERSION, Perl $], $^X" );
