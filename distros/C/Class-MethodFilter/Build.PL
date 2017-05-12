use Module::Build;
Module::Build->new(
  module_name => 'Class::MethodFilter',
  license => 'perl',
  create_makefile_pl => 'passthrough',
)->create_build_script;
