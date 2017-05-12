#!perl -T
use 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::Dropbox' ) || print "Bail out!\n";
}

diag( "Testing Dancer::Plugin::Dropbox $Dancer::Plugin::Dropbox::VERSION, Perl $], $^X" );
