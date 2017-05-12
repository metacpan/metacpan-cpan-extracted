#!/usr/bin/perl;
use strict;
use warnings;

use Test::More;
our $CLASS = 'Child::Socket';
require_ok( $CLASS );

$CLASS->import();
ok( ! __PACKAGE__->can('child'), "No export by default" );

$CLASS->import('child', 'proc_connect');
can_ok( __PACKAGE__, 'child', 'proc_connect' );

my $one = child( sub { 1 });
ok( !$one->ipc, "no ipc by default" );

$one = child(
    sub {
        my $parent = shift;
        $parent->disconnect;
        $parent->connect(10);
        $parent->say( "Hi" );
    },
    socket => 1
);
ok( $one->ipc, "ipc by param" );
$one->disconnect;
$one = proc_connect( $one->socket_file );
is( $one->read, "Hi\n", "Reconnected" );

done_testing;
