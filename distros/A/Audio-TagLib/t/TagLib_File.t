use Test::More tests => 13;
use Path::Class;

BEGIN { use_ok('Audio::TagLib::File') };

my @methods = qw(DESTROY name tag audioProperties save readBlock
                 writeBlock find rfind insert removeBlock readOnly isOpen isValid seek
                 clear tell length );
can_ok("Audio::TagLib::MPEG::File", @methods) 								or 
	diag("can_ok failed");

# Methods tag, audioProperties and save are pure virtual.
# As such, they are not testable here. They are supposed to
# be implemented in TagLib::FLAC::File, TagLib::MPC::File, TagLib::MPEG::File,
# TagLib::Ogg::FLAC::File, TagLib::Ogg::Speex::File, TagLib::Ogg::Vorbis::File,
# TagLib::TrueAudio::File, and TagLib::WavPack::File.

my $file = Path::Class::file( 'sample', 'guitar.mp3' ) . '';
# FileRef doc suggests using particular classes
my $i =  Audio::TagLib::MPEG::File->new($file);
is($i->name(), $file) 											        or 
	diag("method name() failed");
# An error here may indicate file is corrupt
my $blocksize = 1024;
my $block = $i->readBlock($blocksize);
cmp_ok($block->size(), "==", $blocksize) 	                            or 
	diag("method readBlock(blocksize) failed");
cmp_ok($i->readOnly(), '==', 0)                                         or
    diag("$file was read only");
# "Guitar" is the Album Title tag: be careful, changes to tag content changes this value
cmp_ok($i->find(Audio::TagLib::ByteVector->new("Guitar")), "==", 33) or 
	diag("method find(pattern) failed");
$i->seek(0, "End");
cmp_ok($i->tell(), "==", $i->length()) 							        or 
	diag("method seek() and length() failed");
cmp_ok($i->rfind(Audio::TagLib::ByteVector->new("4"), 20), "==", -1) 	or 
	diag("method rfind(pattern, fromOffset) failed");
ok($i->isOpen()) 												        or 
	diag("method isOpen() failed");
ok($i->isValid()) 												        or 
	diag("method isValid() failed");
$i->seek(0);
cmp_ok($i->tell(), "==", 0) 									        or 
	diag("method seek() and tell() failed");

ok(Audio::TagLib::File->isReadable(__FILE__))							or 
	diag("method isReadable(file) failed");
ok(Audio::TagLib::File->isWritable(__FILE__)) 							or 
	diag("method isWritable(name) failed");
