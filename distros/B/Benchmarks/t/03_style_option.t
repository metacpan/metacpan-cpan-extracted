use strict;
use warnings;

use Benchmarks sub {
    my $x = 2;
    +{
        times => sub { $x * $x },
        raise => sub { $x ** 2 },
    };
}, 100, "none";

use Test::More tests => 1;
ok 1;
