use Test::More tests => 8;
use Path::Class;

BEGIN { use_ok('Audio::TagLib::FLAC::File') };

my @methods = qw(new DESTROY ID3v2Tag ID3v1Tag xiphComment
setID3v2FrameFactory streamInfoData streamLength name tag
audioProperties save readBlock writeBlock find rfind insert
removeBlock readOnly isOpen isValid seek clear tell length );
can_ok("Audio::TagLib::FLAC::File", @methods) 							or 
	diag("can_ok failed");

my $file = Path::Class::file( 'sample', 'guitar.flac' ) . '';
my $i = Audio::TagLib::FLAC::File->new($file);
isa_ok($i, "Audio::TagLib::FLAC::File") 								or 
	diag("method new(file) failed");
isa_ok($i->tag(), "Audio::TagLib::Tag") 								or 
	diag("method tag() failed");
isa_ok($i->audioProperties(), "Audio::TagLib::FLAC::Properties") 		or 
	diag("method audioProperties() failed");
my $p = $i->audioProperties();
=pod
This results in a problem on second execution after save()
isa_ok($i->ID3v2Tag(1), "Audio::TagLib::ID3v2::Tag") 					or 
	diag("method ID3v2Tag(t) failed");
 TagLib: FLAC::File::save() --
 This can't be right -- an ID3v2 tag after the start of the FLAC bytestream? 
 Not writing the ID3v2 tag.
=cut
isa_ok($i->ID3v1Tag(1), "Audio::TagLib::ID3v1::Tag") 					or 
	diag("method ID3v1Tag(t) failed");
isa_ok($i->xiphComment(1), "Audio::TagLib::Ogg::XiphComment") 			or 
	diag("method xiphComment(t) failed");
$i->setID3v2FrameFactory(Audio::TagLib::ID3v2::FrameFactory->instance());
# obsolete
=if 0
isa_ok($i->streamInfoData(), "Audio::TagLib::ByteVector") 				or 
	diag("method streamInfoData() failed");
cmp_ok($i->streamLength(), "==", 343788) 						        or 
	diag("method streamLength() failed");
=cut
ok($i->save()) 												            or 
	diag("method save() failed");
