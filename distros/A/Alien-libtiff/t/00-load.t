use strict;
use warnings;
use Test::More;
use Test::Alien;

BEGIN {
    use_ok('Alien::libtiff') or BAIL_OUT('Failed to load Alien::libtiff');
}

alien_ok 'Alien::libtiff';

diag(
    sprintf(
        'Testing Alien::libtiff %s, Perl %s, %s',
        $Alien::sqlite::VERSION, $], $^X
    )
);


done_testing();

