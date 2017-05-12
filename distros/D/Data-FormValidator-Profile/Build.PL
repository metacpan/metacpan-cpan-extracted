use strict;
use warnings;
use Module::Build;

Module::Build->new(
    'module_name'       => 'Data::FormValidator::Profile',
    'dist_author'       => 'Graham TerMarsch (cpan@howlingfrog.com)',
    'license'           => 'perl',
    'create_makefile_pl'=> 'traditional',
    'requires'          => {
        'Data::FormValidator'   => 4.50,
        'List::MoreUtils'       => 0,
        },
    'build_requires'    => {
        'Test::More'            => 0,
        'Test::Exception'       => 0,
        },
    )->create_build_script();
