#   $Id: Build.PL 74 2014-05-23 12:42:51Z adam $;

use Module::Build;

my $build = Module::Build->new(
    module_name => 'Config::Trivial::Storable',
    license     => 'lgpl3',
    requires    => {
        'perl'              => '5.010',
        'Storable'          => '2.24',
        'Config::Trivial'   => '0.70',
    },
    configure_requires => {
        'Module::Build'    => '0.4',
    },
    build_requires => {
        'Module::Build' => '0.40',
        'IO::Capture'   => 0,
        'Test::Pod'     => 0,
        'Test::More'    => 0,
        'Pod::Coverage' => 0,
        'YAML'          => 0,
        'Test::Pod::Coverage'   => 0,
    },
);

$build->create_build_script;
