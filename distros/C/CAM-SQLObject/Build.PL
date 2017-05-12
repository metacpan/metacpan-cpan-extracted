use Module::Build;
Module::Build->new(
                   module_name => 'CAM::SQLObject',
                   license => 'perl',
                   requires => {
                      'CAM::SQLManager'          => '1.00',
                   },
                   recommends => {
                   },
                   build_requires => {
                      'Test::More'               => '0.01',
                   },
                   )->create_build_script;
