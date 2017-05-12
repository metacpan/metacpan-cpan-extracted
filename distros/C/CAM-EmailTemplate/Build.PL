use Module::Build;
Module::Build->new(
                   module_name => 'CAM::EmailTemplate',
                   license => 'perl',
                   requires => {
                      'CAM::Template'            => '0.90',
                   },
                   build_requires => {
                      'Test::More'               => '0.01',
                   },
                   )->create_build_script;
