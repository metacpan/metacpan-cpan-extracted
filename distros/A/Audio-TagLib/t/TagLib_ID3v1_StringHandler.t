use Test::More q(no_plan);

BEGIN { use_ok('Audio::TagLib::ID3v1::StringHandler') };

my @methods = qw(parse render);
can_ok("Audio::TagLib::ID3v1::StringHandler", @methods) 					or 
	diag("can_ok failed");

# This class implements only virtual methods
