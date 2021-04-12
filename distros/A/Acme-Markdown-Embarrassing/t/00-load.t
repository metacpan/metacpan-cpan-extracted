#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Markdown::Embarrassing' ) || print "Bail out!\n";
}

diag( "Testing Acme::Markdown::Embarrassing $Acme::Markdown::Embarrassing::VERSION, Perl $], $^X" );
