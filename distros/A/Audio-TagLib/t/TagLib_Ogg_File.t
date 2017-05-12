use Test::More tests => 9;
use Path::Class;

use lib './include';
use Copy;

BEGIN { use_ok('Audio::TagLib::Ogg::Vorbis::File') };

my @methods = qw(DESTROY packet setPacket firstPageHeader
lastPageHeader name tag audioProperties save
readBlock writeBlock find rfind insert removeBlock readOnly isOpen
isValid seek clear tell length );
can_ok("Audio::TagLib::Ogg::File", @methods) 							or 
	diag("can_ok failed");

my $file = Path::Class::file( 'sample', 'guitar.ogg' ) . '';
my $flacfile = Audio::TagLib::Ogg::Vorbis::File->new($file);
isa_ok($flacfile, "Audio::TagLib::Vorbis::File")                        or
    diag("method Audio::TagLib::Ogg::FLAC->new failed");
isa_ok($flacfile->packet(0), "Audio::TagLib::ByteVector") 				or 
	diag("method packet(i) failed");
isa_ok($flacfile->firstPageHeader(), "Audio::TagLib::Ogg::PageHeader")  or 
	diag("method firstPageHeader() failed");
isa_ok($flacfile->lastPageHeader(), "Audio::TagLib::Ogg::PageHeader") 	or 
	diag("method lastPageHeader() failed");
ok (Copy::Dup( $file))                                                  or
    diag("method Copy::Dup failed");
my $nfile = Audio::TagLib::Ogg::Vorbis::File->new(Copy::DupName($file));
isa_ok($nfile, "Audio::TagLib::Ogg::Vorbis::File")                      or
    diag("method Audio::TagLib::Ogg::Vorbis::File->new failed");
ok($nfile->save())											            or 
	diag("method save() failed");
Copy::Unlink( $file );;
