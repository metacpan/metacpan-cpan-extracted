use Module::Build;

use strict;

my $build = Module::Build->new(
    module_name => 'Data::Phrasebook::Loader::JSON::Syck',
    license => 'perl',
    requires => {
        'Carp'               => '0',
        'Data::Phrasebook'   => '0',
        'JSON::Syck'         => '0',      
        'File::Slurp'        => '0',  
    },
    optional => {
    },
    build_requires => {
        'Test::More'      => '0.47',
        'Test::Exception' => '0.21',
		'File::Spec'      => '0',
		'FindBin'         => '0',        
    },
    create_makefile_pl => 'traditional',
    recursive_test_files => 1,
    add_to_cleanup => [
        'META.yml', '*.bak', '*.gz', 'Makefile.PL',
    ],
);

$build->create_build_script;

