use strict;
use warnings;
use utf8;

use Test::More;

use Cache::utLRU;

exit main();

sub main {
    my %composers = (
        'Grieg' => 'Edvard',
        'Berlioz' => 'Hector',
        'Debussy' => 'Claude',
        'van Beethoven' => 'Ludwig',
        'Bach' => 'Johann Sebastian',
        'Telemann' => 'George Philippe',
        'Handel' => 'Georg Friedrich',
        'Wagner' => 'Richard',
        'Verdi' => 'Giuseppe',
        'Liszt' => 'Franz',
        'Chopin' => 'Frédéric',
        'Tchaikovsky' => 'Pyotr Ilyich',
    );

    my $size = scalar keys %composers;
    my $cache = Cache::utLRU->new();
    my $default_capacity = 1000;
    my $capacity = $cache->capacity;
    is($cache->size, 0, "cache starts life empty");
    is($cache->capacity, $default_capacity, "cache capacity is the default, $default_capacity");

    foreach my $lastname (sort keys %composers) {
        my $firstname = $composers{$lastname};
        $cache->add($lastname, $firstname);
    }
    is($cache->size, $size, "cache grows to $size elements");
    foreach my $lastname (sort keys %composers) {
        my $wanted = $composers{$lastname};
        my $got = $cache->find($lastname);
        is($got, $wanted, "got '$got' for '$lastname'");
    }
    is($cache->size, $size, "cache still has $size elements");

    $cache->clear;
    is($cache->size, 0, "cache ends life empty");

    done_testing;
    return 0;
}
