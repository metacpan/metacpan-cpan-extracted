use Test::More tests => 4;

BEGIN { use_ok('Audio::TagLib::ID3v2::ExtendedHeader') };

my @methods = qw(new DESTROY size setData);
can_ok("Audio::TagLib::ID3v2::ExtendedHeader", @methods) 		or 
	diag("can_ok failed");

my $i = Audio::TagLib::ID3v2::ExtendedHeader->new();
isa_ok($i, "Audio::TagLib::ID3v2::ExtendedHeader") 				or 
	diag("method new failed");
my $data = Audio::TagLib::ByteVector->new("blah blah");
$i->setData($data);
my $j = Audio::TagLib::ID3v2::ExtendedHeader->new();
$j->setData($data);
cmp_ok($i->size(), "==", $j->size()) 							or 
	diag("method setData(bytevector) or size() failed");
