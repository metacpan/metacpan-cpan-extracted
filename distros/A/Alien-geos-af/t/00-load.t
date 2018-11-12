use strict;
use warnings;
use Test::More;
use Test::Alien;

BEGIN {
    use_ok('Alien::geos::af') or BAIL_OUT('Failed to load Alien::geos::af');
}

alien_ok 'Alien::geos::af';

diag(
    sprintf(
        'Testing Alien::geos::af %s, Perl %s, %s',
        $Alien::geos::af::VERSION, $], $^X
    )
);

done_testing();

