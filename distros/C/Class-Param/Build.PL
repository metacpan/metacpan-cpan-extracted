use strict;
use Module::Build;

my $build = Module::Build->new(
    license            => 'perl',
    module_name        => 'Class::Param',
    requires           => {
        'perl'               => 5.006,
        'Carp'               => 0,
        'Encode'             => 0,
        'Tie::Hash::Indexed' => 0.04,
        'Params::Validate'   => 0,
    },
    build_requires     => {
        'Test::More'         => 0,
    },
    create_makefile_pl => 'traditional',
    create_readme      => 1
);

$build->create_build_script;
