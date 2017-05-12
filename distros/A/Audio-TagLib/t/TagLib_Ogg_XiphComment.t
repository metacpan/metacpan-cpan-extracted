use Test::More tests => 18;

BEGIN { use_ok('Audio::TagLib::Ogg::XiphComment') };

my @methods = qw(new DESTROY title artist album comment genre year
track setTitle setArtist setAlbum setComment setGenre setYear setTrack
isEmpty fieldCount fieldListMap vendorID addField removeField render);
can_ok("Audio::TagLib::Ogg::XiphComment", @methods) 		    or 
	diag("can_ok failed");

my $i = Audio::TagLib::Ogg::XiphComment->new();
isa_ok($i, "Audio::TagLib::Ogg::XiphComment") 				    or 
	diag("method new() failed");

$i->setTitle(Audio::TagLib::String->new("Title"));
is($i->title()->toCString(), "Title") 			                or 
	diag("method setTitle(string) and title() failed");
$i->setArtist(Audio::TagLib::String->new("Artist"));
is($i->artist()->toCString(), "Artist") 		                or 
	diag("method setArtist(string) and artist() failed");
$i->setAlbum(Audio::TagLib::String->new("Album"));
is($i->album()->toCString(), "Album") 			                or 
	diag("method setAlbum(string) and album() failed");
$i->setComment(Audio::TagLib::String->new("Comment"));
is($i->comment()->toCString(), "Comment") 		                or 
	diag("method setComment(string) and comment() failed");
$i->setGenre(Audio::TagLib::String->new("Genre"));
is($i->genre()->toCString(), "Genre") 			                or 
	diag("method setGenre(string) and genre() failed");
$i->setYear(1981);
cmp_ok($i->year(), "==", 1981) 					                or 
	diag("method setYear(uint) and year() failed");
$i->setTrack(3);
cmp_ok($i->track(), "==", 3) 					                or 
	diag("method setTrack(uint) and track() failed");
ok(not $i->isEmpty()) 							                or 
	diag("method isEmpty() failed");
cmp_ok($i->fieldCount(), "==", 7) 				                or 
	diag("method fieldCount() failed");
isa_ok($i->fieldListMap(), "Audio::TagLib::Ogg::FieldListMap") 	or 
	diag("method fieldListMap() failed");
like($i->vendorID()->toCString(), qr(^)) 		                or 
	diag("method vendorID() failed");
$i->addField(Audio::TagLib::String->new("TITLE"), 
	Audio::TagLib::String->new("newTitle"));
is($i->title()->toCString(), "newTitle") 		                or
	diag("method addField(key, value) failed");
$i->removeField(Audio::TagLib::String->new("TITLE"));
cmp_ok($i->fieldCount(), "==", 6) 				                or 
	diag("method removeField(key) failed");
cmp_ok($i->render()->size(), "==", 105) 		                or 
	diag("method render() failed");
cmp_ok($i->render(1)->size(), "==", 105) 		                or 
	diag("method render(addFramingBit) failed");
