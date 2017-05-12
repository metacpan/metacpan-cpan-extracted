use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'Catalyst::Plugin::Session::Store::CDBI',
    requires           => { 
        'Catalyst'                  => '5.49',
        'Catalyst::Plugin::Session' => 0,
        'Class::DBI'                => 0,
        'MIME::Base64'              => 0,
        'Storable'                  => 0,
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    test_files   => [
        glob('t/*.t') 
    ]
);
$build->create_build_script;
