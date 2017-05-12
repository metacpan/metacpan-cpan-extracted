use strict;
use warnings;
use Module::Build;

Module::Build->new(
    'module_name'       => 'CSS::Minifier::XS',
    'license'           => 'perl',
    'dist_author'       => 'Graham TerMarsch (cpan@howlingfrog.com)',
    'create_makefile_pl'=> 'traditional',
    'xs_files'          => {
        'XS.xs' => 'lib/CSS/Minifier/XS.xs',
        },
    'build_requires'    => {
        'Test::More'            => 0,
        },
    )->create_build_script();
