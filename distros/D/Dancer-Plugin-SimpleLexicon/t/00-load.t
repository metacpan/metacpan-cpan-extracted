#!perl -T
use 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::SimpleLexicon' ) || print "Bail out!\n";
}

diag( "Testing Dancer::Plugin::SimpleLexicon $Dancer::Plugin::SimpleLexicon::VERSION, Perl $], $^X" );
