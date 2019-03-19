#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CatalystX::Action::Negotiate' ) || print "Bail out!\n";
}

diag( "Testing CatalystX::Action::Negotiate $CatalystX::Action::Negotiate::VERSION, Perl $], $^X" );
