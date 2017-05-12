use Test::More q(no_plan);

BEGIN { use_ok('Audio::TagLib::ByteVectorList') };

my @methods = qw(new DESTROY toByteVector split);
can_ok("Audio::TagLib::ByteVectorList", @methods)		or 
	diag("can_ok failed");

my $i = Audio::TagLib::ByteVectorList->new();
my $j = Audio::TagLib::ByteVectorList->new($i);
isa_ok($i, "Audio::TagLib::ByteVectorList")			    or 
	diag("method new() failed");
isa_ok($j, "Audio::TagLib::ByteVectorList") 			or 
	diag("method new(l) failed");

ok($i->toByteVector()->isEmpty()) 				        or 
	diag("method toByteVector() failed");

my $v = Audio::TagLib::ByteVector->new("This is real test");
my $pattern = Audio::TagLib::ByteVector->new(" ");
# Split "This is a test" into several strings at " "
my $k1 = Audio::TagLib::ByteVectorList->split($v, $pattern);
# Combine the data in $kl using the default sepaarator, " "
# Which shoud reconstitute the original string
is($k1->toByteVector->data(), "This is real test")     or 
	diag("method split(v, pattern) failed");
# There's a bug in taglib 1.5. if one of the split strings ("a instead of "real", for example)
# is of length 1, it's lost
