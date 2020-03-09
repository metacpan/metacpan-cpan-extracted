use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use AWS::XRay qw/ capture /;

subtest "carp", sub {
    local $AWS::XRay::CROAK_INVALID_NAME = 0;
    my $res = capture "my * App", sub {
        "result";
    };
    is $res, "result";
};

subtest "croak", sub {
    local $AWS::XRay::CROAK_INVALID_NAME = 1;
    eval {
        capture "my * App", sub {
            "result";
        };
    };
    diag $@;
    ok $@ =~ /invalid/;
};

done_testing;
