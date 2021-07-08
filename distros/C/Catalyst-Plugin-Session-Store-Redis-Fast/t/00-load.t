#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Catalyst::Plugin::Session::Store::Redis::Fast' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::Plugin::Session::Store::Redis::Fast $Catalyst::Plugin::Session::Store::Redis::Fast::VERSION, Perl $], $^X" );
