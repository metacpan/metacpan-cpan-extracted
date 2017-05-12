use strict;
use warnings;

use Test::More tests => 26;

use ok "Cache::Cascade";

{
	package MemCache;

	sub new { bless {}, shift }
	sub get { $_[0]{$_[1]} }
	sub set { $_[0]{$_[1]} = $_[2] }
	sub remove { delete $_[0]{$_[1]} }
}

my @caches = map { MemCache->new } 1 .. 3;

my $cache = Cache::Cascade->new( caches => \@caches );

isa_ok( $cache, "Cache::Cascade" );

is( $cache->get("foo"), undef, "no key yet" );

$caches[-1]->set( foo => "bar" );
is( $caches[-1]->get("foo"), "bar", "last cache stored" );
is( $caches[0]->get("foo"), undef, "first cache unaffected" );

is( $cache->get("foo"), "bar", "value gotten from lowest" );

$caches[0]->set( foo => "gorch" );

is( $cache->get("foo"), "gorch", "value gotten from highest" );
is( $caches[-1]->get("foo"), "bar", "foo is still bar in lowest" );

$cache->set( foo => "moose" );

is( $_->get("foo"), "moose", "stored in child" ) for @caches;

$cache->set_deep(0);

$cache->set( foo => "elk" );

is( $caches[0]->get("foo"), "elk", "set in highest" );
is( $caches[1]->get("foo"), "moose", "but not in others" );

$cache->remove("foo");

is( $_->get("foo"), undef, "removed from child" ) for @caches;

$cache->float_hits(1);

$caches[-1]->set( foo => "camel" );

is( $caches[0]->get("foo"), undef, "value not yet floated" );

is( $cache->get("foo"), "camel", "get from bottom" );

is( $_->get("foo"), "camel", "value floated" ) for @caches;


$caches[-1]->set( bar => "" );

is( $caches[0]->get("bar"), undef, "value not yet floated" );

is( $cache->get("bar"), "", "get from bottom" );

is( $_->get("bar"), "", "value floated" ) for @caches;

