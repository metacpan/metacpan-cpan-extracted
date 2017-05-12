use Module::Build;

use strict;

my $build = Module::Build->new(
    module_name => 'Catalyst::View::Excel::Template::Plus',
    license => 'perl',
    requires => {
        'Catalyst::Runtime'     => '0',
        'Excel::Template::Plus' => '0.05',
    },
    optional => {
    },
    build_requires => {
        'Test::More'       => '0.62',
        'Test::Exception'  => '0.21',
        'parent'           => '0',
    },
    create_makefile_pl => 'traditional',
    recursive_test_files => 1,
    add_to_cleanup => [
        'META.yml', '*.bak', '*.gz', 'Makefile.PL',
    ],
    meta_merge => {
        resources => {
            repository  => 'http://github.com/stevan/catalyst-view-excel-template-plus/'
        }
    },
);

$build->create_build_script;

