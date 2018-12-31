use strict;
use warnings;
use Test::More;
use Test::Alien;

BEGIN {
    use_ok('Alien::sqlite') or BAIL_OUT('Failed to load Alien::sqlite');
}

alien_ok 'Alien::sqlite';

diag(
    sprintf(
        'Testing Alien::sqlite %s, Perl %s, %s',
        $Alien::sqlite::VERSION, $], $^X
    )
);

done_testing();

