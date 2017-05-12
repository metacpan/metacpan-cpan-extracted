use Test::More tests => 6;

BEGIN { use_ok('Audio::TagLib::ID3v1') };

my @methods = qw(genreList genreMap genre genreIndex);
can_ok("Audio::TagLib::ID3v1", @methods) 								or 
	diag("can_ok failed");

isa_ok(Audio::TagLib::ID3v1->genreList(), "Audio::TagLib::StringList") 		or 
	diag("method genreList() failed");
isa_ok(Audio::TagLib::ID3v1->genreMap(), "Audio::TagLib::ID3v1::GenreMap") 	or 
	diag("method genreMap() failed");
# This depends on the implementation of genre(), which assigns genres to an array,
# the index of which is used as parameter. AFAIK, the contents are not documented 
# outside of mpeg/id3v2/id3v2.2.0.txt in the taglib source. A purist might argue
# that being in the standard is enough.
is(Audio::TagLib::ID3v1->genre(1)->toCString(), "Classic Rock") 		or 
	diag("method genre(index) failed");
cmp_ok(Audio::TagLib::ID3v1->genreIndex(Audio::TagLib::String->new("Classic Rock")),
	"==", 1) or diag("method genreIndex(name) failed");
