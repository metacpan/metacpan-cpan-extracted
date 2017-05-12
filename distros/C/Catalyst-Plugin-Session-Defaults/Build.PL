use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Catalyst::Plugin::Session::Defaults',
    requires           => {
        'Catalyst::Plugin::Session' => 0,
        'Test::use::ok'             => 0,
        'Storable'                  => 0,
    },
    create_readme => 1,
    sign          => 1,
);
$build->create_build_script;

