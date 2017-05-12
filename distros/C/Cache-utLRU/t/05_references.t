use strict;
use warnings;
use utf8;

use Test::More;
use DDP output => 'stdout';

use Cache::utLRU;

exit main();

sub main {
    my %composers = (
        Chopin => {
            name => 'Frédéric',
            country => 'Poland',
            birth => 1810,
            death => 1849,
        },
        Tchaikovsky => {
            name => 'Pyotr Ilyich',
            country => 'Russia',
            birth => 1840,
            death => 1893,
        },
        Bartók => {
            name => 'Béla Bartók',
            country => 'Hungary',
            birth => 1881,
            death => 1945,
        },
    );

    my $size = scalar keys %composers;
    my $cache = Cache::utLRU->new($size);
    is($cache->size, 0, "cache starts life empty");

    foreach my $lastname (sort keys %composers) {
        my $data = $composers{$lastname};
        $cache->add($lastname, $data);
    }
    is($cache->size, $size, "cache grows to $size elements");
    foreach my $lastname (sort keys %composers) {
        my $wanted = $composers{$lastname};
        my $got = $cache->find($lastname);
        is($got, $wanted, "got data for '$lastname'");
        p $got;
    }
    is($cache->size, $size, "cache still has $size elements");

    $cache->clear;
    is($cache->size, 0, "cache ends life empty");

    done_testing;
    return 0;
}
