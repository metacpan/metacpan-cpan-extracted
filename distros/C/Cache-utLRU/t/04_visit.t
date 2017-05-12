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
    my $length = scalar keys %composers;

    my $cache = Cache::utLRU->new($length);
    foreach my $lastname (sort keys %composers) {
        my $firstname = $composers{$lastname};
        $cache->add($lastname, $firstname);
    }

    $cache->visit(sub {
        my ($key, $val) = @_;
        # printf STDERR ("VISIT [%s] => [%s]\n", $key, $val);
        delete $composers{$key};
    });
    is(scalar keys %composers, 0, "visited all $length elements in cache");

    done_testing;
    return 0;
}
