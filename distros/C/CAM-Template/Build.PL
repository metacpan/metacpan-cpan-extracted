use Module::Build;
Module::Build->new(
                   module_name => 'CAM::Template',
                   license => 'perl',
                   requires => {
                   },
                   build_requires => {
                      'Test::More'               => 0,
                   },
                   )->create_build_script;
