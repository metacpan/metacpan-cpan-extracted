use v5.40;
use blib;
use Test2::V0;
use Alien::SDL3;
#
my $sdl3 = Alien::SDL3->new;
isa_ok $sdl3, ['Alien::SDL3'],           'isa Alien::SDL3';
isa_ok $sdl3, ['Alien::Xrepo::Runtime'], 'isa Alien::Xrepo::Runtime';
is [ $sdl3->package_names ], [ 'libsdl3', 'libsdl3_image', 'libsdl3_ttf', 'libsdl3_mixer' ], 'package_names lists the SDL3 family';
#
done_testing;
