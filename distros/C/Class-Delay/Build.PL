use strict;
use Module::Build;

Module::Build->new(
    module_name => "Class::Delay",
    license     => 'perl',
    requires    => {
        'perl'                  => '5.006',
        'Class::Accessor::Fast' => 0,
        'Test::More'            => 0,
    },
    create_makefile_pl => 'passthrough',
   )
  ->create_build_script;


