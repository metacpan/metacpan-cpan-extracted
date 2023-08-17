use strict;
use Test::More 0.98;
#
use_ok 'Alien::SDL3';
#
diag 'Libs:';
diag '  - ' . $_ for sort Alien::SDL3->dynamic_libs;
diag sprintf '%s support: %s', $_, Alien::SDL3->features->{$_} ? 'yes' : 'no'
    for qw[SDL3 SDL3_image SDL3_mixer SDL3_ttf];
#
isa_ok Alien::SDL3->sdldir, 'Path::Tiny';
isa_ok Alien::SDL3->incdir, 'Path::Tiny';
isa_ok Alien::SDL3->libdir, 'Path::Tiny';
#
done_testing;
