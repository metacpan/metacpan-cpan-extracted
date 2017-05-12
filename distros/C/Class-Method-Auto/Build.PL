use strict;

use Module::Build;

Module::Build->new
    ( module_name => 'Class::Method::Auto',
      license     => 'perl',
      create_makefile_pl => 'passthrough',
      requires    => {  },
    )->create_build_script;