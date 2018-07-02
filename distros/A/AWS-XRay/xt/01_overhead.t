use 5.12.0;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";

use AWS::XRay qw/ capture capture_from /;
use Test::More;
use Benchmark qw/ timeit timestr /;

reset();
my $t = timeit(
    1000,
    sub {
        capture "root", sub {
            capture "sub $_", sub {} for ( 1 .. 99 );
        };
    });
diag sprintf("%d loops of 100 captured code took: %s", $t->iters, timestr($t));

ok 1;
done_testing;
