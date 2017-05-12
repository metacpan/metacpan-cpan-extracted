use strict;
use warnings;
use lib qw(inc lib);
use MY::Build;

MY::Build->new(
    'module_name'       => 'Alien::Prototype::Window',
    'license'           => 'perl',
    'dist_author'       => 'Graham TerMarsch (cpan@howlingfrog.com)',
    'create_makefile_pl'=> 'passthrough',
    'requires'          => {
        'perl'                  => '5.6.0',
        'Alien::scriptaculous'  => '1.7.1.1_03',
        },
    'build_requires'    => {
        'Archive::Zip'          => 0,
        'Test::Exception'       => 0,
        },
    )->create_build_script();
