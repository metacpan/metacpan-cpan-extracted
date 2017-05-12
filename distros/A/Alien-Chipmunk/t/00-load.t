use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Alien::Chipmunk') or BAIL_OUT('Failed to load Alien::Chipmunk');
}

diag(
    sprintf(
        'Testing Alien::Chipmunk %f, Perl %f, %s',
        $Alien::Chipmunk::VERSION, $], $^X
    )
);

done_testing();

