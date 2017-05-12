use strict;
use warnings;
use Test::More;
use Compress::LZ4;

eval "use Test::LeakTrace; 1" or do {
    plan skip_all => 'Test::LeakTrace is not installed.';
};

my $try = sub {
    for (1 .. 100) {
        my $c = compress('test' x 100);
        my $d = decompress($c);
    }
};

$try->();

is(leaked_count($try), 0, 'leaks');

done_testing;
