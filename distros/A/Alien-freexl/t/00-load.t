use strict;
use warnings;
use Test::More;
use Test::Alien;

BEGIN {
    use_ok('Alien::freexl') or BAIL_OUT('Failed to load Alien::freexl');
}

alien_ok 'Alien::freexl';

diag(
    sprintf(
        'Testing Alien::freexl %s, Perl %s, %s',
        $Alien::freexl::VERSION, $], $^X
    )
);
diag "Install type is " . Alien::freexl->install_type;

done_testing();

