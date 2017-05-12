use Test::More tests => 5;

BEGIN { use_ok('Audio::TagLib::ID3v2::UnknownFrame') };

my @methods = qw(new DESTROY toString data frameID size setData
setText render headerSize textDelimiter);
can_ok("Audio::TagLib::ID3v2::UnknownFrame", @methods) 				or 
	diag("can_ok failed");

my $i = Audio::TagLib::ID3v2::UnknownFrame->new(
	Audio::TagLib::ByteVector->new("XXXX\0\0\0\0\0\0", 10));
isa_ok($i, "Audio::TagLib::ID3v2::UnknownFrame") 					or 
	diag("method new(data) failed");
is($i->toString()->toCString(), "") 								or 
	diag("method toString() failed");
is($i->data()->data(), undef) 										or 
	diag("method data() failed");
