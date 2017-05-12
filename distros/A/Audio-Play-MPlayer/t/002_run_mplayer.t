#!/usr/bin/perl -w

use strict;
use warnings;
use lib 't/lib';
use ApmTest;
use Test::More tests => 4;

use Audio::Play::MPlayer;

my $child_died = 0;
$SIG{CHLD} = sub { $child_died = 1 };

my $player = eval {
    Audio::Play::MPlayer->new( mplayerargs => [ '-af', 'volume=-200' ] );
};
if( my $e = $@ ) {
    BAIL_OUT( "Can't start mplayer" );
}

sleep 1; # give some time to die...

ok( $player->{pid}, "mplayer pid $player->{pid}" );
ok( !$child_died, "child still running" );
ok( kill( 0, $player->{pid} ), 'process exists' );

undef $player;

ok( $child_died, "child stopped" );
