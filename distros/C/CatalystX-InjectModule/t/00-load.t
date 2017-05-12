#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CatalystX::InjectModule' ) || print "Bail out!\n";
}

diag( "Testing CatalystX::InjectModule $CatalystX::InjectModule::VERSION, Perl $], $^X" );
