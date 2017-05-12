use Test::More tests => 12;
BEGIN { use_ok('Audio::TagLib::ID3v1::Tag') };

my @methods = qw(new DESTROY render title artist album comment genre
                 year track setTitle setArtist setAlbum setComment setGenre setYear
                 setTrack fileIdentifier setStringHandler);
can_ok("Audio::TagLib::ID3v1::Tag", @methods) 			        or 
	diag("can_ok failed");

my $i = Audio::TagLib::ID3v1::Tag->new();
isa_ok($i, "Audio::TagLib::ID3v1::Tag") 				        or 
	diag("method new() failed");
# This interface assumes that $file has id3v1 tags.
# Regretably, that format is obsolete, and no such files are available
#my $j = Audio::TagLib::ID3v1::Tag->new($file, $offset);
#isa_ok($j, "Audio::TagLib::ID3v1::Tag") 				        or 
#	diag("method new(file, tagOffset) failed");

# This function is virtual. No implementations are available
# Audio::TagLib::ID3v1::Tag->setStringHandler()

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
$i->setGenre(Audio::TagLib::String->new("Classic Rock"));
is($i->genre()->toCString(), "Classic Rock") 	                or 
	diag("method setGenre(string) and genre() failed");
$i->setYear(1981);
cmp_ok($i->year(), "==", 1981) 					                or 
	diag("method setYear(uint) and year() failed");
$i->setTrack(3);
cmp_ok($i->track(), "==", 3) 					                or 
	diag("method setTrack(uint) and track() failed");

isa_ok($i->render(), "Audio::TagLib::ByteVector") 		        or 
	diag("method render() failed");
is(Audio::TagLib::ID3v1::Tag->fileIdentifier()->data(), "TAG")  or 
	diag("method fileIdentifier() failed");
