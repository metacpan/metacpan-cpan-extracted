# Build.PL
# 
# installer for Class::FakeAttributes


use strict;

use Module::Build;


Module::Build->new
(
  module_name => 'Class::FakeAttributes',
  license => 'artistic',
  create_makefile_pl => 'passthrough',
  requires =>
  {
    'perl' => '5.6.0',
    'NEXT' => '0.60',
  },
)->create_build_script;
