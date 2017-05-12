use Test::More tests => 8;

BEGIN { use_ok('Audio::TagLib::ID3v1::GenreMap::Iterator') };

# This code depends on the ordinals in the file taglib-1.11/taglib/mpeg/id3v1/id3v1genres.cpp
# As such, results are highly version-dependent.
# This test should be paired with a test of Audio::TagLib::ID3v1->genreList()
# But that'sforanother day
my @methods = qw(new DESTROY data next last);
can_ok("Audio::TagLib::ID3v1::GenreMap::Iterator", @methods) or diag("can_ok failed");

my $genremap = Audio::TagLib::ID3v1->genreMap();
my $i = $genremap->begin();
isa_ok($i, "Audio::TagLib::ID3v1::GenreMap::Iterator") 				or 
	diag("method Audio::TagLib::ID3v1::genreMap() failed");
isa_ok(Audio::TagLib::ID3v1::GenreMap::Iterator->new(), 
	"Audio::TagLib::ID3v1::GenreMap::Iterator") 					or 
	diag("method new() failed");
isa_ok(Audio::TagLib::ID3v1::GenreMap::Iterator->new($i), 
	"Audio::TagLib::ID3v1::GenreMap::Iterator") 					or 
	diag("method new(i) failed");

# Drum Solo
cmp_ok($i->data(), "==", 123) 										or 
	diag("method data() failed");
# Synthpop (I'm guessing)
cmp_ok($i->next()->data(), "==", 148) 								or 
	diag("method next() failed");
cmp_ok((--$i)->data(), "==", 123) 									or 
	diag("method last() failed");
