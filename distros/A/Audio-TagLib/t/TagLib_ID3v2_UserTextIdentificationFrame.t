use Test::More tests => 7;

BEGIN { use_ok('Audio::TagLib::ID3v2::UserTextIdentificationFrame') };

my @methods = qw(new DESTROY toString description setDescription
setText textEncoding setTextEncoding fieldList frameID size setData
render headerSize textDelimiter);
can_ok("Audio::TagLib::ID3v2::UserTextIdentificationFrame", @methods) 		or 
	diag("can_ok failed");

my $i = Audio::TagLib::ID3v2::UserTextIdentificationFrame->new();
isa_ok($i, "Audio::TagLib::ID3v2::UserTextIdentificationFrame") 			or 
	diag("method new() failed");
$i->setText(Audio::TagLib::String->new("blah blah"));
like($i->toString()->toCString(), qr(blah\sblah)) 					or 
	diag("method setText(s) and toString() failed");
$i->setText(Audio::TagLib::StringList->new(Audio::TagLib::String->new("blah blah blah")));
like($i->toString()->toCString(), qr(blah\sblah\sblah)) 			or 
	diag("method setText(l) failed");
$i->setDescription(Audio::TagLib::String->new("desc"));
is($i->description()->toCString(), "desc") 							or 
	diag("method setDescription(desc) and description() failed");
isa_ok($i->fieldList(), "Audio::TagLib::StringList") 						or 
	diag("method fieldList() failed");
=if 0
TODO: {
local $TODO = "method find(Tag *tag, String &desc) not exported";
$f = $i->find("desc");
isa_ok($f,  "Audio::TagLib::ID3v2::UserTextIdentificationFrame") 			or
    diag("method find failed");
}
=cut
