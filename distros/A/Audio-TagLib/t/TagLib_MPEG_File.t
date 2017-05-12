use Test::More tests => 16;
use Path::Class;


use lib './include';
use Copy;

BEGIN { use_ok('Audio::TagLib::MPEG::File') };

my @methods = qw(new DESTROY ID3v2Tag ID3v1Tag APETag
                 setID3v2FrameFactory strip firstFrameOffset nextFrameOffset
                 previousFrameOffset lastFrameOffset name tag audioProperties save
                 readBlock writeBlock find rfind insert removeBlock readOnly isOpen
                 isValid seek clear tell length);
can_ok("Audio::TagLib::MPEG::File", @methods) 						or 
	diag("can_ok failed");

# Tests are dependent on the structure of this file.
# If that changes, then ...
my $file = Path::Class::file( 'sample', 'guitar.mp3' ) . '';
my $i = Audio::TagLib::MPEG::File->new($file);
isa_ok($i, "Audio::TagLib::MPEG::File") 							or 
	diag("method new(file) failed");
isa_ok($i->tag(), "Audio::TagLib::Tag") 							or 
	diag("method tag() failed");
isa_ok($i->audioProperties(), "Audio::TagLib::MPEG::Properties") 	or 
	diag("method audioProperties() failed");
isa_ok($i->ID3v2Tag(1), "Audio::TagLib::ID3v2::Tag") 				or 
	diag("method ID3v2Tag(t) failed");
isa_ok($i->ID3v1Tag(1), "Audio::TagLib::ID3v1::Tag") 				or 
	diag("method ID3v1Tag(t) failed");
isa_ok($i->APETag(1), "Audio::TagLib::APE::Tag") 					or 
	diag("method APETag(t) failed");
ok($i->strip("APE")) 											    or 
	diag("method strip(tags) failed");
cmp_ok($i->firstFrameOffset(), "==", 39) 							or 
	diag("method firstFrameOffset() failed");
cmp_ok($i->nextFrameOffset(925), "==", 1672) 						or 
	diag("method nextFrameOffset(p) failed");
cmp_ok($i->previousFrameOffset(27690), "==", 27557) 				or 
	diag("method previousFrameOffset(p) failed");
cmp_ok($i->lastFrameOffset(), "==", 159770) 			    		or 
	diag("method lastFrameOffset() failed");
ok (Copy::Dup( $file))                                              or
    diag("method Copy::Dup failed");
my $nfile = Audio::TagLib::MPEG::File->new(Copy::DupName($file));
isa_ok($nfile, "Audio::TagLib::MPEG::File")                         or
    diag("method Audio::TagLib::MPEG::File::new failed");
ok($nfile->save())											        or 
	diag("method save() failed");
Copy::Unlink($file);;
