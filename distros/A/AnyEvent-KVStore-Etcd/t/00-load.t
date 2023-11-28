#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'AnyEvent::KVStore::Etcd' ) || print "Bail out!\n";
}

diag( "Testing AnyEvent::KVStore::Etcd $AnyEvent::KVStore::Etcd::VERSION, Perl $], $^X" );
