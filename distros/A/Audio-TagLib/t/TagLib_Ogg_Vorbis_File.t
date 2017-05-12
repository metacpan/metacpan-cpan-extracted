use Test::More tests => 8;
use Path::Class;

use lib './include';
use Copy;

BEGIN { use_ok('Audio::TagLib::Ogg::Vorbis::File') };

my @methods = qw(DESTROY name tag audioProperties save readBlock writeBlock find rfind
                 insert removeBlock readOnly isOpen isValid seek clear tell length);
can_ok("Audio::TagLib::Ogg::Vorbis::File", @methods)   					   or 
	diag("can_ok failed");

my $file = Path::Class::file( 'sample', 'guitar.ogg' ) . '';
my $i = Audio::TagLib::Vorbis::File->new($file);
isa_ok($i, "Audio::TagLib::Ogg::Vorbis::File")                             or
    diag("Audio::TagLib::Ogg::Vorbis::File failed");

isa_ok($i->tag(), "Audio::TagLib::Ogg::XiphComment") 	       		       or 
    diag("method tag() failed");
isa_ok($i->audioProperties(), "Audio::TagLib::Ogg::Vorbis::Properties")    or 
    diag("method audioProperties() failed");
ok (Copy::Dup( $file))                                                     or
    diag("method Copy::Dup failed");
my $nfile = Audio::TagLib::Ogg::Vorbis::File->new(Copy::DupName($file));
isa_ok($nfile, "Audio::TagLib::Ogg::Vorbis::File")                         or
    diag("method Audio::TagLib::Ogg::Vorbis::File->new failed");
ok($nfile->save())											               or 
	diag("method save() failed");
Copy::Unlink( $file );;
