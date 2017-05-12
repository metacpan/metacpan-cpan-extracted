use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'Catalyst::View::HTML::Template',
    requires           => { 'Catalyst' => 5.7,
                            'HTML::Template' => 0 },
    create_makefile_pl => 'passthrough',
    test_files         => [ glob('t/*.t') ]
);
$build->create_build_script;
