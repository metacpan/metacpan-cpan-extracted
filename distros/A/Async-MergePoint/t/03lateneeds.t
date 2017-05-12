#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;
use Test::Fatal;

use Async::MergePoint;

my $merge = Async::MergePoint->new();
ok( defined $merge, 'Empty MergePoint created' );

my $done;
$merge->close( on_finished => sub { $done = 1 } );

is( $done, 1, 'Closing a null MergePoint fires callback' );

$merge = Async::MergePoint->new();

$merge->needs( 'foo' );

$merge->close( on_finished => sub { $done = 2 } );

is( $done, 1, 'Closing a not ready MergePoint does not callback' );

ok( exception { $merge->needs( 'bar' ) },
    'Extending an already-closed MergePoint fails' );

$merge->done( 'foo' );

is( $done, 2, 'Callback now fires' );
