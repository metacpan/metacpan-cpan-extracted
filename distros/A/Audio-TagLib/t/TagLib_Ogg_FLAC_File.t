use Test::More tests => 13;
use Path::Class;

use lib './include';
use Copy;

BEGIN { use_ok('Audio::TagLib::Ogg::FLAC::File');
        use_ok('Audio::TagLib::Ogg::XiphComment') };

my @methods = qw(new DESTROY streamLength hasXiphComment audioProperties);
can_ok("Audio::TagLib::Ogg::FLAC::File", @methods) 				 	 or 
	diag("can_ok failed");
can_ok('Audio::TagLib::Ogg::XiphComment', qw(artist setArtist))      or
    diag('can_ok #2 failed');

my $file = Path::Class::file( 'sample', 'empty_flac.ogg' ) . '';

my $i = Audio::TagLib::Ogg::FLAC::File->new($file);
isa_ok($i, "Audio::TagLib::Ogg::FLAC::File") 						 or 
	diag("method new(file) failed");

my $XiphComment;
if ($i->hasXiphComment() ) {
    isa_ok($i->tag(), "Audio::TagLib::Ogg::XiphComment") 		     or 
        diag("method tag() failed");
    $XiphComment = $i->tag();

}
else {ok(!$i->hasXiphComment(), "$file has no XiphComment") }

if ($i->audioProperties()) {
    isa_ok($i->audioProperties(), "Audio::TagLib::FLAC::Properties") or 
        diag("method audioProperties() failed");
}
else {ok(!$i->audioProperties(), "$file has no audioProperties")}

$XiphComment->setArtist(Audio::TagLib::String->new('The Artist'));
    
cmp_ok($XiphComment->artist()->toCString(), 'eq', 'The Artist')      or
    diag('method artist() failed');
    
$XiphComment->setArtist(Audio::TagLib::String->new('Another Artist'));
    
cmp_ok($XiphComment->artist()->toCString(), 'eq', 'Another Artist')  or
    diag('method artist() failed');
    
cmp_ok($i->streamLength(), "==", 829) 							     or 
	diag("method streamLength() failed");

# save assumes that the comment method is defined for the file
# However, there appears to be no method to set it.
# The sample file was ripped off from the TagLib tests
# To reproduce, comment out the delete f in taglib-1.9.1/tests/test_oggflac.cpp
#
ok (Copy::Dup($file))                                                or
    diag("method Copy::Dup failed");
my $nfile = Audio::TagLib::Ogg::FLAC::File->new(Copy::DupName($file));
isa_ok($nfile, "Audio::TagLib::Ogg::FLAC::File")                     or
    diag("method Audio::TagLib::Ogg::FLAC::File::new failed");
ok($nfile->save())											         or 
	diag("method save() failed");
Copy::Unlink($file);
