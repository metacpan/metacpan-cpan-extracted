use File::Spec;
use Test::More tests => 20;

BEGIN { use_ok('Audio::TagLib::APE::Tag') };

my @methods = qw(new DESTROY render title artist album comment genre
                 year track setTitle setArtist setAlbum setComment setGenre setYear
                 setTrack footer itemListMap removeItem addValue setItem fileIdentifier);
can_ok("Audio::TagLib::APE::Tag", @methods) 			                            or 
	diag("can_ok failed");

my $i = Audio::TagLib::APE::Tag->new();
isa_ok($i, "Audio::TagLib::APE::Tag") 					                            or 
	diag("method new() failed");

#my $file = "sample/guitar.mp3";
my $file = File::Spec->catfile('sample', 'guitar.mp3');
my $tagOffset = 0;
# See t/TagLib_ID3v2_Tag.t for an explanation of this
my $file_object = Audio::TagLib::MPEG::File->new($file, $tagOffset);
isa_ok($file_object, "Audio::TagLib::MPEG::File") 							        or 
	diag("method new(file, tagOffset) failed");
my $j = Audio::TagLib::APE::Tag->new($file_object, $tagOffset);
isa_ok($j, "Audio::TagLib::APE::Tag") 					                            or 
	diag("method new(file, tagOffset) failed");

$i->setTitle(Audio::TagLib::String->new("Title"));
is($i->title()->toCString(), "Title") 			                                    or 
	diag("method setTitle(string) and title() failed");
$i->setArtist(Audio::TagLib::String->new("Artist"));
is($i->artist()->toCString(), "Artist") 		                                    or 
	diag("method setArtist(string) and artist() failed");
$i->setAlbum(Audio::TagLib::String->new("Album"));
is($i->album()->toCString(), "Album") 			                                    or 
	diag("method setAlbum(string) and album() failed");
$i->setComment(Audio::TagLib::String->new("Comment"));
is($i->comment()->toCString(), "Comment") 		                                    or 
	diag("method setComment(string) and comment() failed");
$i->setGenre(Audio::TagLib::String->new("Genre"));
is($i->genre()->toCString(), "Genre") 			                                    or 
	diag("method setGenre(string) and genre() failed");
$i->setYear(1981);
cmp_ok($i->year(), "==", 1981) 					                                    or 
	diag("method setYear(uint) and year() failed");
$i->setTrack(3);
cmp_ok($i->track(), "==", 3) 					                                    or 
	diag("method setTrack(uint) and track() failed");

isa_ok($i->render(), "Audio::TagLib::ByteVector") 		                            or 
	diag("method render() failed");
isa_ok($i->footer(), "Audio::TagLib::APE::Footer") 	                                or 
	diag("method footer() failed");
my $map = $i->itemListMap();
tie my %map, ref $map, $map;
isa_ok(tied %map, "Audio::TagLib::APE::ItemListMap") 	                            or 
	diag("method itemListMap() failed");
cmp_ok(scalar(%map), "==", 7) 					                                    or 
	diag("method itemListMap() failed");
$i->removeItem(Audio::TagLib::String->new("TITLE"));
cmp_ok(scalar(%map), "==", 6) 					                                    or 
	diag("method removeItem(key) failed");
$i->addValue(Audio::TagLib::String->new("TITLE"),
	Audio::TagLib::String->new("Title"));
is($map{Audio::TagLib::String->new("TITLE")}->
	toString()->toCString(), "Title") 			                                    or 
	diag("method addValue(key, value) failed");
################################################################
# setItem will NOT replaced the old value of key
################################################################
$i->removeItem(Audio::TagLib::String->new("ARTIST"));
$i->setItem(Audio::TagLib::String->new("ARTIST"), 
	Audio::TagLib::APE::Item->new(Audio::TagLib::String->new("1"), 
	Audio::TagLib::String->new("Bon Jovi")));
is($map{Audio::TagLib::String->new("ARTIST")}->toString()->toCString(), 
	"Bon Jovi") 								                                    or 
	diag("method setItem(key, item) failed");
is(Audio::TagLib::APE::Tag->fileIdentifier()->data(), "APETAGEX")                   or 
	diag("method fileIdentifier() failed");
