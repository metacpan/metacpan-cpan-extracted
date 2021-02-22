use strict;
use warnings;
use lib qw(inc lib);
use MY::Build;

MY::Build->new(
    'module_name'       => 'Alien::scriptaculous',
    'license'           => 'perl',
    'dist_author'       => 'Graham TerMarsch (cpan@howlingfrog.com)',
    'create_makefile_pl'=> 'passthrough',
    'requires'          => {
        'perl'                  => '5.6.0',
        'Alien::Prototype'      => '1.6.0',
        },
    'build_requires'    => {
        'Archive::Tar'          => 0,
        'Test::Exception'       => 0,
        },
    'meta_merge'        => {
        'x_deprecated'          => 1,
        'bugtracker' => {
            'web' => 'https://github.com/bleargh45/Alien-scriptaculous/issues',
            },
        'repository' => {
            'type' => 'git',
            'url'  => 'git://github.com/bleargh45/Alien-scriptaculous.git',
            'web'  => 'https://github.com/bleargh45/Alien-scriptaculous',
            },
        },
    )->create_build_script();
