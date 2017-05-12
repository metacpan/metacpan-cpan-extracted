use Module::Build;
Module::Build->new(
                   module_name => 'CAM::UserApp',
                   license => 'perl',
                   requires => {
                      'CAM::App'                 => '1.00',
                      'CAM::Session'             => '1.00',
                   },
                   recommends => {
                   },
                   build_requires => {
                      'Test::More'               => '0.01',
                   },
                   )->create_build_script;
