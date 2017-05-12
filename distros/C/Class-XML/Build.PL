use Module::Build;
Module::Build->new(
  module_name => 'Class::XML',
  license => 'perl',
  requires => {
    'Test::More' => '0.0',
    'XML::XPath' => '1.13',
    'Carp'       => '0.0',
    'Class::Accessor' => '0.19',
    'Class::Data::Inheritable' => '0.02',
  },
  create_makefile_pl => 'passthrough',
)->create_build_script;
