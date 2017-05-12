
use Module::Build;

Module::Build->new(
    module_name => 'Acme::Roman',
    license     => 'perl', 
    dist_author      => 'Adriano R. Ferreira <ferreira@cpan.org>',
    dist_version_from => 'lib/Acme/Roman.pm',

    requires    => {
        'strict'          => 0,
        'warnings'        => 0,
        'base'            => 0,
        'version'         => 0,
        'overload'        => 0,
        'Class::Accessor' => 0,
        'Roman'           => 0,
        'Carp'            => 0,
        'Scalar::Util'    => 0,
    },

    build_requires => {
        'Test::More'      => 0,
    },
    recommends     => {
        Test::Pod           => 1.18,
        Test::Pod::Coverage => 1.04, 
    },
    meta_merge     => {
        configure_requires   => { 
            'Module::Build' => 0, 
        },
    },

    create_readme => 1,


)->create_build_script;
