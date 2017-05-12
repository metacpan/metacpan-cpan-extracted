use Module::Build;

use 5.008001;

use strict;
use warnings;

my $build = Module::Build->new(
    module_name => 'DBD::Mock',
    license     => 'perl',
    requires    => {
        'perl' => '5.6.0',
        'DBI'  => 1.30,
    },
    optional       => {},
    build_requires => {
        'Test::More'      => '0.47',
        'Test::Exception' => '0.31',
    },
    create_makefile_pl   => 'traditional',
    recursive_test_files => 1,
    add_to_cleanup       => [ '*.bak', ],

    meta_merge => {
        resources => {
            repository  => 'https://github.com/bluescreen10/dbd-mock',
        },
    },
);

$build->create_build_script;
