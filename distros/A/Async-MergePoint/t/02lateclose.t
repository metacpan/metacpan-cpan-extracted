#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;
use Test::Fatal;

use Async::MergePoint;

my $merge = Async::MergePoint->new( needs => [qw( foo )]);
ok( defined $merge, 'MergePoint created' );

$merge->done( 'foo' );

my $done;
$merge->close( on_finished => sub { $done = 1 } );

is( $done, 1, 'Closing a now-ready MergePoint fires callback' );

$merge = Async::MergePoint->new( needs => [qw( foo )]);

$merge->close( on_finished => sub { $done = 2 } );

is( $done, 1, 'Closing a not ready MergePoint does not callback' );

$merge->done( 'foo' );

is( $done, 2, 'Closing MergePoint fires callback' );

$merge = Async::MergePoint->new(
   needs => [qw( bar )],
   on_finished => sub { },
);

ok( exception { $merge->close( on_finished => sub { } ) },
    'closing an already-closed MergePoint fails' );
