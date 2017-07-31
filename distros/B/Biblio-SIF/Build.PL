use strict;
use warnings;

use Module::Build;

my %module_build_args = (
    'build_requires' => {
        'Module::Build' => 0,
        'Test::More' => 0
    },
    'configure_requires' => {
        'Module::Build' => 0,
    },
    'dist_abstract' => 'Voyager ILS SIF file operations',
    'dist_author' => [ 'Paul Hoffman <paul@flo.org>' ],
    'dist_name' => 'Biblio-SIF',
    'license' => 'perl',
    'module_name' => 'Biblio::SIF',
    'recommends' => {},
    'recursive_test_files' => 1,
    'requires' => {
        'Carp' => 0,
        'Package::Constants' => 0,
    },
    'script_files' => [ glob('scripts/*') ],
);

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
