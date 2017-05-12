use Test::More tests => 4;

BEGIN { use_ok('Audio::TagLib::ID3v2::Footer') };

my @methods = qw(new DESTROY render size);
can_ok("Audio::TagLib::ID3v2::Footer", @methods) 		or 
	diag("can_ok failed");

my $i = Audio::TagLib::ID3v2::Footer->new();
isa_ok($i, "Audio::TagLib::ID3v2::Footer") 				or 
	diag("method new failed");
cmp_ok($i->size, "==", 10)                              or
    diag("size() is not 10");
