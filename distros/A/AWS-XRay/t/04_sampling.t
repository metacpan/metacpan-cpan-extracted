use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";

use AWS::XRay qw/ capture capture_from /;
use Test::More;
use t::Util qw/ reset segments /;

srand(1); # fix seed

subtest "disable", sub {
    reset();
    AWS::XRay->sampling_rate(0);
    capture "root", sub {
        capture "sub $_", sub {} for ( 1 .. 100 );
    };
    my @seg = segments();
    ok scalar(@seg) == 0;
};

subtest "enable", sub {
    reset();
    AWS::XRay->sampling_rate(1);
    capture "root", sub {
        capture "sub $_", sub {} for ( 1 .. 100 );
    };
    my @seg = segments();
    ok scalar(@seg) == 101;
};

subtest "50%", sub {
    reset();
    AWS::XRay->sampling_rate(0.5);
    for ( 1 .. 1000 ) {
        capture "root $_", sub {};
    }
    my @seg = segments();
    ok scalar(@seg) >  400;
    ok scalar(@seg) <= 600;
};

subtest "50% sub", sub {
    for ( 1 .. 10 ) {
        reset();
        AWS::XRay->sampling_rate(0.5);
        capture "root", sub {
            capture "sub $_", sub {} for ( 1 .. 100 );
        };
        my @seg = segments();
        ok scalar(@seg) == 101 || scalar(@seg) == 0;
        diag @seg if @seg < 100 && @seg > 1;
    }
};

done_testing;
