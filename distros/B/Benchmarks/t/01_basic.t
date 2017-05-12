use strict;
use warnings;

use Benchmarks sub {
    my $x = 1;
    +{
        times => sub { $x * $x },
        raise => sub { $x ** 2 },
    };
}, 100;

use Test::More tests => 1;
ok 1;
