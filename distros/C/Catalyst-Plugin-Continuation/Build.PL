use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Catalyst::Plugin::Continuation',
    requires           => {
        'Catalyst'                  => '5.691',
        'Data::Visitor'             => '0.05',
        'Catalyst::Plugin::Session' => '0',
        'Test::WWW::Mechanize'      => '0',
        'Moose'                     => '0.05',
    },
    create_readme => 1,
    sign          => 1,
);
$build->create_build_script;

