use strict;
use warnings;
use utf8;
use Test::More;

use Test::More;
use Test::Time time => 1;
use Cache::Scalar::WithExpiry;
use Time::HiRes qw//;

{
    # CORE::GLOBAL::time() is overrided by Test::Time and use it
    no warnings;
    *Time::HiRes::time = sub { time() };
}

subtest 'cache_with_expiry' => sub {
    my @sequence = (
        [0, 1, 2],
        [0, 1, 2],
        [5, 2, 4],
        [0, 2, 4],
        [5, 3, 6],
        [5, 4, 8],
    );
    for my $try (@sequence) {
        my ($sleep, $expected, $expected2) = @_;

        sleep $sleep;
        my $val = cache_with_expiry {
            my $i;
            (sub {++$i}->(), 5);
        };
        my ($val2,) = cache_with_expiry {
            my $i;
            (sub {++$i}->(), 5);
        };
        my $val3 = cache_with_expiry {
            my $i;
            (sub {++$i;++$i;}->(), 5);
        };

        ok $val,  $expected;
        ok $val2, $expected;
        ok $val3, $expected2;
    }
};

done_testing;
