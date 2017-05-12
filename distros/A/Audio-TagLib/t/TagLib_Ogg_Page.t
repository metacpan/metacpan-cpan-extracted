use Test::More q(no_plan);

BEGIN { use_ok('Audio::TagLib::Ogg::Page') };

my @methods = qw(new DESTROY fileOffset header firstPacketIndex
setFirstPacketIndex containsPacket packetCount packets size render
paginate);
can_ok("Audio::TagLib::Ogg::Page", @methods) 							or 
	diag("can_ok failed");

SKIP: {
skip "more test needed", 1 if 1;
ok(1);
}
