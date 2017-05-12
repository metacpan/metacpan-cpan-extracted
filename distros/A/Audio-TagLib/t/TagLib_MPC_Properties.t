use Test::More tests => 2;

BEGIN { use_ok('Audio::TagLib::MPC::Properties') };

my @methods = qw(new DESTROY length bitrate sampleRate channels
mpcVersion);
can_ok("Audio::TagLib::MPC::Properties", @methods) 					or 
	diag("can_ok failed");

SKIP: {
skip "APE demo too large", 0 if 1;
}
