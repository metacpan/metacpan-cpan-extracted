use Module::Build;

use strict;

my $build = Module::Build->new(
    module_name => 'Catalyst::View::GD',
    license => 'perl',
    requires => {   
        'Catalyst::Runtime' => '0',
        'GD'                => '0',
    },
    optional => {
    },
    build_requires => {
        'Test::More'       => '0.62',
        'Test::Exception'  => '0.21',
        'Test::Image::GD'  => '0.03',
    },
    create_makefile_pl => 'traditional',
    recursive_test_files => 1,
    add_to_cleanup => [
        'META.yml', '*.bak', '*.gz', 'Makefile.PL',
    ],
);

$build->create_build_script;

