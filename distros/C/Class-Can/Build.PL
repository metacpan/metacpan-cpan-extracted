use strict;
use Module::Build;
Module::Build->new(
    module_name => 'Class::Can',
    license     => 'perl',
    requires    => {
        'perl' => 5.006,
	'Devel::Symdump' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    create_makefile_pl => 'traditional',
   )->create_build_script;
