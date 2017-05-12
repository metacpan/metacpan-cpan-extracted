use strict;
use Module::Build;
 	
my $build = Module::Build->new(
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'Catalyst::Plugin::Markdown',
    requires           => {
        'Catalyst'       => '5.30',
        'Text::Markdown' => '1.0.2',
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    test_files   => [
        glob('t/*.t')
    ]
);
$build->create_build_script;
