#!/usr/bin/perl -w

use Test::More tests => 81;

BEGIN { use_ok( 'DCOP::Amarok::Player' ) }
my $player = DCOP::Amarok::Player->new( user => "$ENV{USER}" );
ok( defined $player, "new() defined the object" );
isa_ok( $player, 'DCOP::Amarok::Player' );

SKIP: {
	skip( "Only works when amarok is installed", 6 )
		unless ( `amarok --version` );

	is( $player->playPause(), '', "   PlayPause" ) or
		diag( "*** Amarok needs to be open." );
	is( $player->stop(),     '', "   Stop" ) or
		diag( "*** Amarok needs to be open." );
}

can_ok( $player, 'album' );
can_ok( $player, 'artist' );
can_ok( $player, 'bitrate' );
can_ok( $player, 'comment' );
can_ok( $player, 'configEqualizer' );
can_ok( $player, 'coverImage' );
can_ok( $player, 'currentTime' );
can_ok( $player, 'dynamicModeStatus' );
can_ok( $player, 'elapsed' );
can_ok( $player, 'elapsedsecs' );
can_ok( $player, 'enableDynamicMode' );
can_ok( $player, 'enableOSD' );
can_ok( $player, 'enableRandomMode' );
can_ok( $player, 'enableRepeatPlaylist' );
can_ok( $player, 'enableRepeatTrack' );
can_ok( $player, 'encodedURL' );
can_ok( $player, 'engine' );
can_ok( $player, 'equalizerEnabled' );
can_ok( $player, 'functions' );
can_ok( $player, 'fwd' );
can_ok( $player, 'genre' );
can_ok( $player, 'getRandom' );
can_ok( $player, 'getVolume' );
can_ok( $player, 'interfaces' );
can_ok( $player, 'isPlaying' );
can_ok( $player, 'lyrics' );
can_ok( $player, 'lyricsByPath' );
can_ok( $player, 'mediaDeviceMount' );
can_ok( $player, 'mediaDeviceUmount' );
can_ok( $player, 'mute' );
can_ok( $player, 'new' );
can_ok( $player, 'next' );
can_ok( $player, 'nowPlaying' );
can_ok( $player, 'path' );
can_ok( $player, 'pause' );
can_ok( $player, 'play' );
can_ok( $player, 'playPause' );
can_ok( $player, 'prev' );
can_ok( $player, 'queueForTransfer' );
can_ok( $player, 'randomModeStatus' );
can_ok( $player, 'repeatPlaylistStatus' );
can_ok( $player, 'repeatTrackStatus' );
can_ok( $player, 'rew' );
can_ok( $player, 'sampleRate' );
can_ok( $player, 'score' );
can_ok( $player, 'seek' );
can_ok( $player, 'seekRelative' );
can_ok( $player, 'setContextStyle' );
can_ok( $player, 'setEqualizer' );
can_ok( $player, 'setEqualizerEnabled' );
can_ok( $player, 'setEqualizerPreset' );
can_ok( $player, 'setLyricsByPath' );
can_ok( $player, 'setScore' );
can_ok( $player, 'setScoreByPath' );
can_ok( $player, 'setVolume' );
can_ok( $player, 'showBrowser' );
can_ok( $player, 'showOSD' );
can_ok( $player, 'status' );
can_ok( $player, 'stop' );
can_ok( $player, 'title' );
can_ok( $player, 'toggleRandom' );
can_ok( $player, 'totalTime' );
can_ok( $player, 'totaltimesecs' );
can_ok( $player, 'track' );
can_ok( $player, 'trackCurrentTime' );
can_ok( $player, 'trackPlayCounter' );
can_ok( $player, 'trackTotalTime' );
can_ok( $player, 'transferCliArgs' );
can_ok( $player, 'transferDeviceFiles' );
can_ok( $player, 'type' );
can_ok( $player, 'vol' );
can_ok( $player, 'volDn' );
can_ok( $player, 'volUp' );
can_ok( $player, 'volumeDown' );
can_ok( $player, 'volumeUp' );
can_ok( $player, 'year' );
