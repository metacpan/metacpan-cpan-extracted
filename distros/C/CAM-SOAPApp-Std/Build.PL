use Module::Build;
Module::Build->new(
                   module_name => 'CAM::SOAPApp::Std',
                   license => 'perl',
                   requires => {
                      'CAM::SOAPApp'             => '1.00',
                   },
                   recommends => {
                   },
                   build_requires => {
                      'Test::More'               => '0.01',
                   },
                   )->create_build_script;
