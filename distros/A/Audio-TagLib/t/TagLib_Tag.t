use Test::More tests => 2;

BEGIN { use_ok('Audio::TagLib::Tag') };

my @methods = qw(DESTROY title artist album comment genre year track
setTitle setArtist setAlbum setComment setGenre setYear setTrack
isEmpty );
can_ok("Audio::TagLib::Tag", @methods) 			or 
	diag("can_ok failed");
