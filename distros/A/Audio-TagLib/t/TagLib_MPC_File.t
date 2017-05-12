use Test::More tests => 10;
use Path::Class;

use lib './include';
use Copy;

BEGIN { use_ok('Audio::TagLib::MPC::File') };

my @methods = qw(new DESTROY ID3v1Tag APETag remove name tag
audioProperties save readBlock writeBlock find rfind insert
removeBlock readOnly isOpen isValid seek clear tell length );
can_ok("Audio::TagLib::MPC::File", @methods) 							or 
	diag("can_ok failed");

my $file = Path::Class::file( 'sample', 'guitar.mp3' ) . '';
my $i = Audio::TagLib::MPC::File->new($file);
isa_ok($i, "Audio::TagLib::MPC::File") 							    	or 
	diag("method new(file) failed");
isa_ok($i->tag(), "Audio::TagLib::Tag") 								or 
	diag("method tag() failed");
isa_ok($i->audioProperties(), "Audio::TagLib::MPC::Properties") 		or 
	diag("method audioProperties() failed");
isa_ok($i->ID3v1Tag(1), "Audio::TagLib::ID3v1::Tag") 					or 
	diag("method ID3v1Tag(t) failed");
isa_ok($i->APETag(1), "Audio::TagLib::APE::Tag") 						or 
	diag("method APETag(t) failed");
ok (Copy::Dup( $file))                                                  or
    diag("method Copy::Dup failed");
my $nfile = Audio::TagLib::MPC::File->new(Copy::DupName($file));
isa_ok($nfile, "Audio::TagLib::MPC::File")                                      or
    diag("method Audio::TagLib::MPC::File->new failed");
ok($nfile->save())											            or 
	diag("method save() failed");
Copy::Unlink( $file );;
