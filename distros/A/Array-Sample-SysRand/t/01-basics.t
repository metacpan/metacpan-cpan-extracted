#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Array::Sample::SysRand qw(sample_sysrand);
use Storable;

sub sample_sysrand_ok {
    my ($args, $results) = @_;

    my $ok = 1;
    for my $i (1..10) {
        my @res = sample_sysrand(@$args);
        my $has_match;
        for my $j (0..$#{$results}) {
            if (Storable::freeze(\@res) eq Storable::freeze($results->[$j])) {
                $has_match++;
                last;
            }
        }
        unless ($has_match) {
            diag "Result ", explain(\@res), " doesn't match any of ",
                explain($results);
            ok 0;
        }
    }
    ok 1;
}

subtest "basics" => sub {
    is_deeply([sample_sysrand([], 0)], []);
    is_deeply([sample_sysrand([], 1)], []);

    is_deeply([sample_sysrand([qw/a/], 0)], []);
    is_deeply([sample_sysrand([qw/a/], 1)], [qw/a/]);

    sample_sysrand_ok(
        [[qw/a b c d/], 1],
        [
            [qw/a/],
            [qw/b/],
            [qw/c/],
            [qw/d/],
        ],
    );

    sample_sysrand_ok(
        [[qw/a b c d/], 2],
        [
            [qw/a c/],
            [qw/b d/],
            [qw/c a/],
            [qw/d b/],
        ],
    );
};

subtest "opt:pos=1" => sub {
    sample_sysrand_ok(
        [[qw/a b c d/], 1, {pos=>1}],
        [
            [0],
            [1],
            [2],
            [3],
        ],
    );

    sample_sysrand_ok(
        [[qw/a b c d/], 2, {pos=>1}],
        [
            [0,2],
            [1,3],
            [2,0],
            [3,1],
        ],
    );
};

DONE_TESTING:
done_testing;
