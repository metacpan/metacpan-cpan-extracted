use warnings;
use Test::More;
use Data::Dumper;
use Capture::Tiny qw/capture_stderr/;
use Encode qw(decode_utf8);

BEGIN { use_ok("Bio::Gonzales::Util::Log"); }

my $l = Bio::Gonzales::Util::Log->new();


my $stderr = capture_stderr {
$l->debug("testdebug");
};

$stderr = decode_utf8($stderr);

like($stderr, qr/^\[\d+ \w+ \d\d:\d\d:\d\d\] \[DEBUG\]: testdebug$/, "log debug test");

done_testing();

