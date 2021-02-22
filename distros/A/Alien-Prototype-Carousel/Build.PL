use strict;
use warnings;
use lib qw(inc lib);
use MY::Build;

MY::Build->new(
    'module_name'       => 'Alien::Prototype::Carousel',
    'license'           => 'perl',
    'dist_author'       => 'Graham TerMarsch (cpan@howlingfrog.com)',
    'create_makefile_pl'=> 'passthrough',
    'requires'          => {
        'perl'                  => '5.6.0',
        'Alien::scriptaculous'  => 0,
        },
    'build_requires'    => {
        'Test::Exception'       => 0,
        },
    'meta_merge' => {
        'x_deprecated'          => 1,
        'bugtracker' => {
            'web'  => 'https://github.com/bleargh45/Alien-Prototype-Carousel/issues',
            },
        'repository' => {
            'type' => 'git',
            'url'  => 'git://github.com/bleargh45/Alien-Prototype-Carousel.git',
            'web'  => 'https://github.com/bleargh45/Alien-Prototype-Carousel',
            },
        },
    )->create_build_script();
