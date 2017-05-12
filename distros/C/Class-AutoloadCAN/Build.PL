use Module::Build;
Module::Build->new(
  module_name => "Class::AutoloadCAN",
  license => 'perl',
  create_makefile_pl => 'traditional',
)->create_build_script;
