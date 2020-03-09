use 5.12.0;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";

use AWS::XRay qw/ capture capture_from /;
use Test::More;
use t::Util qw/ reset segments /;

subtest "disable", sub {
    reset();
    AWS::XRay->sampler(sub { 0 });
    capture "root", sub {
        capture "sub $_", sub { }
            for (1 .. 100);
    };
    my @seg = segments();
    ok scalar(@seg) == 0;
};

subtest "enable", sub {
    reset();
    AWS::XRay->sampler(sub { 1 });
    capture "root", sub {
        capture "sub $_", sub { }
            for (1 .. 100);
    };
    my @seg = segments();
    ok scalar(@seg) == 101;
};

subtest "odd", sub {
    reset();
    AWS::XRay->sampler(sub { state $count = 0; $count++ % 2 == 0 });
    for (1 .. 1000) {
        capture "root $_", sub { };
    }
    my @seg = segments();
    ok scalar(@seg) == 500;
};

subtest "odd_from", sub {
    reset();
    AWS::XRay->sampler(sub { state $count = 0; $count++ % 2 == 0 });
    for (1 .. 1000) {
        capture_from "", "root $_", sub { };
    }
    my @seg = segments();
    ok scalar(@seg) == 500;
};

done_testing;
