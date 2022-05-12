use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";

use AWS::XRay ();
use Test::More;
use Encode qw/decode_utf8/;

local $AWS::XRay::ENABLED = 1;

subtest "utf8" => sub {
    my $segment = AWS::XRay::Segment->new({ name => decode_utf8("あ") });
    ok $segment->close;
};

done_testing;
