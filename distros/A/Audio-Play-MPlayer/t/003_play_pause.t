#!/usr/bin/perl -w

use strict;
use warnings;
use lib 't/lib';
use ApmTest;
use Test::More tests => 5;

my $player = get_player;

is( $player->state, 0, 'player starts stopped' );

$player->load( 't/data/ex-mp30.mp3' );
sleep 0.8;
$player->poll;
is( $player->state, 2, 'player is playing' );

$player->pause;
sleep 0.8;
$player->poll;
is( $player->state, 1, 'player is paused' );

$player->pause;
sleep 0.8;
$player->poll;
is( $player->state, 2, 'player is playing' );

$player->stop;
sleep 0.8;
$player->poll;
is( $player->state, 0, 'player is stopped' );
