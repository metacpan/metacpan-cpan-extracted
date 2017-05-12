#!/usr/bin/perl -w

use strict;

use Test::More tests => 9;
use Test::Fatal;

use Async::MergePoint;

ok( exception { Async::MergePoint->new( needs => "hello", on_finished => sub { "DUMMY" } ) },
    'needs not ARRAY' );

ok( exception { Async::MergePoint->new( needs => ['foo'], on_finished => "goodbye" ) },
    'on_finished not CODE' );

my %items;

my $merge = Async::MergePoint->new(
   needs => [qw( red )],

   on_finished => sub { %items = @_; },
);

ok( defined $merge, '$merge defined' );
isa_ok( $merge, "Async::MergePoint", '$merge isa Async::MergePoint' );

is_deeply( \%items, {}, '%items before done of one item' );

$merge->done( red => '#f00' );

is_deeply( \%items, { red => '#f00' }, '%items after done of one item' );

%items = ();

$merge = Async::MergePoint->new(
   needs => [qw( blue green )],

   on_finished => sub { %items = @_; },
);

$merge->done( green => '#0f0' );

is_deeply( \%items, {}, '%items after one of 1/2 items' );

$merge->done( blue => '#00f' );

is_deeply( \%items, { blue => '#00f', green => '#0f0' }, '%items after done 2/2 items' );

$merge = Async::MergePoint->new(
   needs => [qw( purple )],
   on_finished => sub { "DUMMY" },
);

ok( exception { $merge->done( "orange" => 1 ) },
    'done something not needed fails' );
