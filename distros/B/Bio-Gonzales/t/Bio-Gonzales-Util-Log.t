use warnings;
use Test::More;
use Data::Dumper;
use Capture::Tiny qw/capture_stderr/;

BEGIN { use_ok("Bio::Gonzales::Util::Log"); }

my $l = Bio::Gonzales::Util::Log->new();


my $stderr = capture_stderr {
$l->debug("testdebug");
};

like($stderr, qr/^\[\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\] \[DEBUG\] testdebug$/, "log debug test");

done_testing();

