use strict;
use warnings;
use Test::More;
use Test::Alien;

BEGIN {
    use_ok('Alien::Proj4') or BAIL_OUT('Failed to load Alien::Proj4');
}

alien_ok 'Alien::Proj4';

diag(
    sprintf(
        'Testing Alien::Proj4 %s, Perl %s, %s',
        $Alien::Proj4::VERSION, $], $^X
    )
);

done_testing();

