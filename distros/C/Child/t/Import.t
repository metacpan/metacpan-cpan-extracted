#!/usr/bin/perl;
use strict;
use warnings;

use Test::More 0.88;
our $CLASS = 'Child';
require_ok( $CLASS );

$CLASS->import();
ok( ! __PACKAGE__->can('child'), "No export by default" );

$CLASS->import('child');
can_ok( __PACKAGE__, 'child' );
my $one = child( sub { 1 });
ok( !$one->ipc, "no ipc by default" );

$one = child( sub { 1 }, pipe => 1 );
ok( $one->ipc, "ipc by param" );

done_testing;
