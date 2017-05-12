use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'Date::Holidays::NO',
    requires           => { 
	    'No::Dato' => 1.10,
    	    'Date::Holidays::Abstract' => 0,
	    'Test::More' => 0 
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    test_files   => [
        glob('t/*.t') 
    ]
);
$build->create_build_script;
