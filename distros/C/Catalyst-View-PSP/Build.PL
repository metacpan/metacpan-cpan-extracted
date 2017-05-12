use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'Catalyst::View::PSP',
    requires           => { Catalyst => 5, 'Text::PSP' => 1.013 },
    create_makefile_pl => 'passthrough',
    test_files         => [ glob('t/*.t') ]
);
$build->create_build_script;
