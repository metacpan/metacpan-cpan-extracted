use strict;
use Module::Build;

Module::Build
  ->new( module_name => "Class::Accessor::Lvalue",
         license     => 'perl',
         build_requires => {
             'Test::More' => 0,
         },
         requires => {
             'Want'            => 0,
             'Class::Accessor' => 0,
         },
         create_makefile_pl => 'traditional',
       )
  ->create_build_script;
