use Test::More tests => 12;

BEGIN { use_ok('Audio::TagLib::ID3v2::AttachedPictureFrame') };

my @methods = qw(new DESTROY toString textEncoding setTextEncoding
                 mimeType setMimeType type setType description setDescription picture
                 setPicture frameID size setData setText render headerSize textDelimiter);
can_ok("Audio::TagLib::ID3v2::AttachedPictureFrame", @methods) 		or 
	diag("can_ok failed");

my $i = Audio::TagLib::ID3v2::AttachedPictureFrame->new();
isa_ok($i, "Audio::TagLib::ID3v2::AttachedPictureFrame") 			or 
	diag("method new() failed");
my $bv = Audio::TagLib::ByteVector->new("a dummy picture");
is($bv->data(), "a dummy picture")                                  or
    diag("failed ByteVector for a dummy picture");
cmp_ok($bv->size(), '==', 15)		                                or 
	diag("test ByteVector has bad size " . $bv->size());
# Message TagLib: A picture frame must contain at least 5 bytes.
# may be ignored
$frm = Audio::TagLib::ID3v2::AttachedPictureFrame->new($bv);
note('The above diagnostic is not a test failure');
isa_ok($frm, "Audio::TagLib::ID3v2::AttachedPictureFrame")			or 
	diag("method new(data) failed");
$i->render();
$i->setTextEncoding("UTF8");
is($i->textEncoding(), "UTF8") 										or 
	diag("method setTextEncoding(encode) and textEncoding() failed");
$i->setMimeType(Audio::TagLib::String->new("image/jpeg"));
is($i->mimeType()->toCString(), "image/jpeg") 						or 
	diag("method setMimeType(t) and mimeType() failed");
$i->setType("Other");
is($i->type(), "Other") 											or 
	diag("method setType(t) and type() failed");
$i->setDescription(Audio::TagLib::String->new("description"));
is($i->description()->toCString(), "description") 					or 
	diag("method setDescription(desc) and description() failed");
is($i->toString()->toCString(), "description [image/jpeg]") 		or 
	diag("method toString() failed");
$i->setPicture(Audio::TagLib::ByteVector->new("a dummy picture"));
is($i->picture()->data(), "a dummy picture") 						or 
	diag("method setPicture(p) and picture() failed");
