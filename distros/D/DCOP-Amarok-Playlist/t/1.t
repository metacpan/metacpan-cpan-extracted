#!/usr/bin/perl -w

use Test::More tests => 24;

BEGIN { use_ok('DCOP::Amarok::Playlist') };
my $playlist = DCOP::Amarok::Playlist->new( user => "$ENV{USER}" );
ok( defined $playlist, "new() defined the object" );
isa_ok( $playlist, "DCOP::Amarok::Playlist" );

can_ok( $playlist, 'addMedia' );
can_ok( $playlist, 'addMediaList' );
can_ok( $playlist, 'clearPlaylist' );
can_ok( $playlist, 'functions' );
can_ok( $playlist, 'getActiveIndex' );
can_ok( $playlist, 'getTotalTrackCount' );
can_ok( $playlist, 'interfaces' );
can_ok( $playlist, 'new' );
can_ok( $playlist, 'notStopAfterCurrent' );
can_ok( $playlist, 'playByIndex' );
can_ok( $playlist, 'playMedia' );
can_ok( $playlist, 'popupMessage' );
can_ok( $playlist, 'removeCurrentTrack' );
can_ok( $playlist, 'repopulate' );
can_ok( $playlist, 'saveCurrentPlaylist' );
can_ok( $playlist, 'saveM3uAbsolute' );
can_ok( $playlist, 'saveM3uRelative' );
can_ok( $playlist, 'setStopAfterCurrent' );
can_ok( $playlist, 'shortStatusMessage' );
can_ok( $playlist, 'shufflePlaylist' );
can_ok( $playlist, 'togglePlaylist' );
