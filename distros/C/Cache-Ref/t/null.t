#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use ok 'Cache::Ref::Null';

my $cache = Cache::Ref::Null->new;

is( $cache->get("foo"), undef, "no value for get" );
$cache->set("foo" => 42);
is( $cache->get("foo"), undef, "no value for after set" );

done_testing;

# ex: set sw=4 et:

