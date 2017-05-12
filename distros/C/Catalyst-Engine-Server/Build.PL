use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'Catalyst::Engine::Server',
    requires           => {
        'Catalyst'       => 5.2,
        'HTTP::Parser'   => 0,
        'HTTP::Request'  => 0,
        'HTTP::Response' => 0,
        'Net::Server'    => 0
    },
    create_makefile_pl => 'passthrough',
    test_files   => [
        glob('t/*.t') 
    ],
    create_readme=>1,
);
$build->create_build_script;
