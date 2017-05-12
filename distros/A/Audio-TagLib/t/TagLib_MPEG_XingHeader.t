use Test::More q(no_plan);

BEGIN { use_ok('Audio::TagLib::MPEG::XingHeader') };

my @methods = qw(new DESTROY isValid totalFrames totalSize
xingHeaderOffset);
can_ok("Audio::TagLib::MPEG::XingHeader", @methods) 					or 
	diag("can_ok failed");

SKIP: {
skip "more test needed", 1 if 1;
ok(1);
}
