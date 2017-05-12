use strict;

use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'Class::ClassDecorator',
      license         => 'perl',
      requires        => { NEXT => 0 },
      sign            => 1,
    )->create_build_script;
