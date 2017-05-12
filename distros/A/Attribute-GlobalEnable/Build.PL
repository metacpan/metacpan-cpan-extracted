use Module::Build;

Module::Build->new(
  module_name       => 'Attribute::GlobalEnable',
  license           => 'perl',
  requires          => {
                         'Attribute::Handlers' => 0,
                         'Carp'                => 0,
                         'Test::More'          => 0,
                       },
)->create_build_script();


