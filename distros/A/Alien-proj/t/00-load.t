use strict;
use warnings;
use Test::More;
use Test::Alien;

BEGIN {
    use_ok('Alien::proj') or BAIL_OUT('Failed to load Alien::proj');
}

alien_ok 'Alien::proj';

diag(
    sprintf(
        'Testing Alien::proj %s, Perl %s, %s',
        $Alien::proj::VERSION, $], $^X
    )
);

done_testing();

