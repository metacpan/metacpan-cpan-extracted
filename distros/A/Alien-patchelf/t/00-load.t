use strict;
use warnings;
use Test::More;
use Test::Alien;

BEGIN {
    use_ok('Alien::patchelf') or BAIL_OUT('Failed to load Alien::patchelf');
}

alien_ok 'Alien::patchelf';

diag(
    sprintf(
        'Testing Alien::patchelf %s, Perl %s, %s',
        $Alien::patchelf::VERSION, $], $^X
    )
);


diag '';
diag 'Install type is ' . Alien::patchelf->install_type;
#diag 'patchelf version is ' . Alien::patchelf->version;

done_testing();

