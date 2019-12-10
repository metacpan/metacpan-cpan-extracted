#!/usr/bin/perl
use strict;
use warnings;
no warnings 'uninitialized';

use Data::ObjectStore;
use Data::RecordStore;

use lib 't/lib';
use test::TestThing;
use OtherThing;

use Data::Dumper;
use File::Copy;
use File::Copy::Recursive qw/dircopy/;
use File::Temp qw/ :mktemp tempdir /;
use File::Path qw/ remove_tree /;
use Test::More;
use Carp;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

use Data::ObjectStore;
    
BEGIN {
    use_ok( "Data::ObjectStore::Cache" ) || BAIL_OUT( "Unable to load 'Data::ObjectStore::Cache'" );
}

my $cache = Data::ObjectStore::Cache->new( 3 );
for my $l ("a".."f") {
    $cache->stow( $l, uc($l) );
}
is( $cache->fetch('f'), 'F', 'last still cached' );
for my $l (qw( a b e f ) ) {
    is( $cache->fetch( $l ), uc($l), "cache still has $l" );
}
for my $l (qw( c d ) ) {
    is( $cache->fetch( $l ), undef, "cache no longer has $l" );
}

# cache allows one more than its size
is( $cache->entries, 4, "has 4 entries" );

my $dir = tempdir( CLEANUP => 1 );
my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $dir, CACHE => $cache );
my $root = $store->load_root_container;
{
    my $foo = $root->set_foo( $store->create_container );
    my $fooid = $foo->[0];
    is( ref($store->fetch($fooid)), "Data::ObjectStore::Container", "cache still had the foo" );
}
$store->empty_cache;
is( $cache->entries, 0, "cache is cleared" );
ok( $root->get_foo, "foo could be got after cache cleared" );

$store = Data::ObjectStore->open_store( DATA_PROVIDER => $dir );
$store->empty_cache;
pass( "store didnt complain about emptying non existant cache" );



done_testing;
