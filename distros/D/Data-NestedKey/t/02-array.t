#!/usr/bin/env perl
use strict;
use warnings;

use Data::NestedKey;

use Test::More;

# top-level array
my $arr = Data::NestedKey->new( [ { name => 'a' }, { name => 'b' } ] );
is_deeply( $arr->get('[0]'), { name => 'a' }, 'root [0]' );
is( $arr->get('[0].name'),  'a', 'root [0].name' );
is( $arr->get('[-1].name'), 'b', 'root [-1].name' );

# make sure normal paths still work (regression)
my $h = Data::NestedKey->new( { items => [ 10, 20, 30 ] } );
is( $h->get('items[0]'),  10, 'keyed subscript still works' );
is( $h->get('items[-1]'), 30, 'negative index still works' );

done_testing;
