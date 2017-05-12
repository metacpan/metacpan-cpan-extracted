use Test::More tests => 7;

BEGIN { use_ok('Audio::TagLib::ID3v2::TextIdentificationFrame') };

my @methods = qw(new DESTROY toString setText textEncoding
setTextEncoding fieldList frameID size setData setText render
headerSize textDelimiter);
can_ok("Audio::TagLib::ID3v2::TextIdentificationFrame", @methods) 			or 
	diag("can_ok failed");

my $i = Audio::TagLib::ID3v2::TextIdentificationFrame->new(
	Audio::TagLib::ByteVector->new("XXXX\0\0\0\0\0\0", 10));
isa_ok($i, "Audio::TagLib::ID3v2::TextIdentificationFrame") 				or 
	diag("method new(type, encoding) failed");
$i->setText(Audio::TagLib::String->new("test of the frame"));
is($i->toString()->toCString(), "test of the frame") 						or 
	diag("method setText(s) and toString() failed");
$i->setText(Audio::TagLib::StringList->new(Audio::TagLib::String->new("more text of the frame")));
is($i->toString()->toCString(), "more text of the frame") 					or 
	diag("method setText(l) failed");
$i->setTextEncoding("UTF16BE");
is($i->textEncoding(), "UTF16BE") 						        			or 
	diag("method setTextEncoding(t) and textEncoding() failed");
isa_ok($i->fieldList(), "Audio::TagLib::StringList") 						or 
	diag("method fieldList() failed");
