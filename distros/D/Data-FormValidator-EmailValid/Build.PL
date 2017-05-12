use strict;
use warnings;
use Module::Build;

Module::Build->new(
    'module_name'        => 'Data::FormValidator::EmailValid',
    'license'            => 'perl',
    'dist_author'        => 'Graham TerMarsch (cpan@howlingfrog.com)',
    'create_makefile_pl' => 'traditional',
    'requires'           => {
        'Data::FormValidator' => 4,
        'Email::Valid'        => 0,
    },
    'recommends' => {
        'Net::DNS' => 0,
    },
    'meta_merge' => {
        'resources' => {
            'repository' => 'https://github.com/bleargh45/Data-FormValidator-Email',
        },
    },
)->create_build_script();
