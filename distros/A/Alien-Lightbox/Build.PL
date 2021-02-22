use strict;
use warnings;
use lib qw(inc lib);
use MY::Build;

MY::Build->new(
    'module_name'       => 'Alien::Lightbox',
    'license'           => 'perl',
    'dist_author'       => 'Graham TerMarsch (cpan@howlingfrog.com)',
    'create_makefile_pl'=> 'passthrough',
    'requires'          => {
        'perl'                  => '5.6.0',
        'Alien::scriptaculous'  => 0,
        },
    'build_requires'    => {
        'Archive::Zip'          => 0,
        'Test::Exception'       => 0,
        },
    'meta_merge'        => {
        'x_deprecated'          => 1,
        'bugtracker' => {
            'web' => 'https://github.com/bleargh45/Alien-Lightbox/issues',
            },
        'repository' => {
            'type' => 'git',
            'url'  => 'git://github.com/bleargh45/Alien-Lightbox.git',
            'web'  => 'https://github.com/bleargh45/Alien-Lightbox',
            },
        },
    )->create_build_script();
