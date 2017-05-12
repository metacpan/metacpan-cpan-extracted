use Test::More tests => 20;
use Path::Class;

BEGIN { use_ok('Audio::TagLib::ID3v2::Tag');
        use_ok('Audio::TagLib::MPEG::File') };

my @methods = qw(new DESTROY title artist album comment genre year
                 track setTitle setArtist setAlbum setComment setGenre setYear setTrack
                 isEmpty header extendedHeader footer frameListMap frameList addFrame
                 removeFrame removeFrames render);
can_ok("Audio::TagLib::ID3v2::Tag", @methods) 								or 
	diag("can_ok #1 failed");
can_ok("Audio::TagLib::MPEG::File", qw(ID3v2Tag)) 							or 
	diag("can_ok #2 failed");

# This is one way to create a ID3V2 Tag object.
# If you wan't to fool with tags, this will work
# However, if you're looking to fool with tags in
# a file, how do you get to the file? One way is with
# a FileRef object (which see), but working with a File
# object is difficult, because its new() is hard to find
my $straight_tag = Audio::TagLib::ID3v2::Tag->new();
isa_ok($straight_tag, "Audio::TagLib::ID3v2::Tag") 							or 
	diag("method new() failed");

# Now we're going to test getting the Tag object form a file
# For this, we need to look upstream to the MPEG object
my $file = Path::Class::file( 'sample', 'guitar.mp3' ) . '';
my $tagOffset = 0;
my $file_object = Audio::TagLib::MPEG::File->new($file, $tagOffset);
isa_ok($file_object, "Audio::TagLib::MPEG::File") 							or 
	diag("method new(file, tagOffset) failed");
my $file_tag_object = $file_object->ID3v2Tag();
isa_ok($file_tag_object, "Audio::TagLib::ID3v2::Tag") 						or 
	diag("method new(file, tagOffset, factory) failed");

# Now exercise the property methods
$file_tag_object->setTitle(Audio::TagLib::String->new("Title"));
is($file_tag_object->title()->toCString(), "Title") 						or 
	diag("method setTitle(string) and title() failed");
$file_tag_object->setArtist(Audio::TagLib::String->new("Artist"));
is($file_tag_object->artist()->toCString(), "Artist") 						or 
	diag("method setArtist(string) and artist() failed");
$file_tag_object->setAlbum(Audio::TagLib::String->new("Album"));
is($file_tag_object->album()->toCString(), "Album") 						or 
	diag("method setAlbum(string) and album() failed");
$file_tag_object->setComment(Audio::TagLib::String->new("Comment"));
is($file_tag_object->comment()->toCString(), "Comment") 					or 
	diag("method setComment(string) and comment() failed");
$file_tag_object->setGenre(Audio::TagLib::String->new("Genre"));
is($file_tag_object->genre()->toCString(), "Genre") 						or 
	diag("method setGenre(string) and genre() failed");
$file_tag_object->setYear(1981);
cmp_ok($file_tag_object->year(), "==", 1981) 								or 
	diag("method setYear(uint) and year() failed");
$file_tag_object->setTrack(3);
cmp_ok($file_tag_object->track(), "==", 3) 									or 
	diag("method setTrack(uint) and track() failed");
ok(not $file_tag_object->isEmpty()) 										or 
	diag("method isEmpty() failed");
isa_ok($file_tag_object->header(), "Audio::TagLib::ID3v2::Header") 			or 
	diag("method header() failed");
# As of 11.1, a size of 0 is created. This will fail when the code is improved.
ok($file_tag_object->extendedHeader()) 									or 
	diag("method extendedHeader() failed");
ok(not $file_tag_object->footer()) 											or 
	diag("method footer() failed");
isa_ok($file_tag_object->frameList(), "Audio::TagLib::ID3v2::FrameList") 	or 
	diag("method frameList() failed");
isa_ok($file_tag_object->render(), "Audio::TagLib::ByteVector") 			or 
	diag("method render() failed");
