#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'AnyEvent::KVStore' ) || print "Bail out!\n";
    use_ok( 'AnyEvent::KVStore::Driver' ) || print "Bail out!\n";
    use_ok( 'AnyEvent::KVStore::Hash' ) || print "Bail out!\n";
}

diag( "Testing AnyEvent::KVStore $AnyEvent::KVStore::VERSION, Perl $], $^X" );
