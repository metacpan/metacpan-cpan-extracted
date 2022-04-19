use strict;
use warnings;
use Test::More;
use Test::Alien;

BEGIN {
    use_ok('Alien::spatialite') or BAIL_OUT('Failed to load Alien::spatialite');
}

alien_ok 'Alien::spatialite';

diag(
    sprintf(
        'Testing Alien::spatialite %s, Perl %s, %s',
        $Alien::spatialite::VERSION, $], $^X
    )
);

done_testing();

