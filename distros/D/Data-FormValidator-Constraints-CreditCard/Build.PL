use strict;
use warnings;
use Module::Build;

Module::Build->new(
    'module_name'       => 'Data::FormValidator::Constraints::CreditCard',
    'dist_author'       => 'Graham TerMarsch (cpan@howlingfrog.com)',
    'license'           => 'perl',
    'create_makefile_pl'=> 'traditional',
    'requires'          => {
        'Data::FormValidator'   => 4,
        'Business::CreditCard'  => 0.30,
        },
    'build_requires'    => {
        'Test::More'            => 0,
        },
    )->create_build_script();
