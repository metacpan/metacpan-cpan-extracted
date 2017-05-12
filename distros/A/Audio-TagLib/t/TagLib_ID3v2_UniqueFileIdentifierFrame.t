use Test::More tests => 8;

BEGIN { use_ok('Audio::TagLib::ID3v2::UniqueFileIdentifierFrame') };

my @methods = qw(new DESTROY owner identifier setOwner setIdentifier
toString frameID size setData setText render headerSize textDelimiter);
can_ok("Audio::TagLib::ID3v2::UniqueFileIdentifierFrame", @methods) 		or 
	diag("can_ok failed");

my $owner = Audio::TagLib::String->new("owner");
my $id = Audio::TagLib::ByteVector->new("id");
my $i = Audio::TagLib::ID3v2::UniqueFileIdentifierFrame->new($owner, $id);
isa_ok($i, "Audio::TagLib::ID3v2::UniqueFileIdentifierFrame") 				or 
	diag("method new(owner,id) failed");
is($i->owner()->toCString(), $owner->toCString()) 					or 
	diag("method owner() failed");
is($i->identifier()->data(), $id->data()) 							or 
	diag("method identifier() failed");
my $newowner = Audio::TagLib::String->new("newowner");
my $newid = Audio::TagLib::ByteVector->new("newid");
$i->setOwner($newowner);
is($i->owner()->toCString(), $newowner->toCString()) 				or 
	diag("method setOwner(s) failed");
$i->setIdentifier($newid);
is($i->identifier()->data(), $newid->data()) 						or 
	diag("method setIdentifier(v) failed");
is($i->toString()->toCString(), "") 								or 
	diag("method toString() failed");
