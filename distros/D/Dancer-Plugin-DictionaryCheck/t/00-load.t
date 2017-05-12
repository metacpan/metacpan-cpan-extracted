#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::DictionaryCheck' ) || print "Bail out!\n";
}

diag( "Testing Dancer::Plugin::DictionaryCheck $Dancer::Plugin::DictionaryCheck::VERSION, Perl $], $^X" );
