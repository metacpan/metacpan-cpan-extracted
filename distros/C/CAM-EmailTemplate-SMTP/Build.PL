use Module::Build;
Module::Build->new(
                   module_name => 'CAM::EmailTemplate::SMTP',
                   license => 'perl',
                   requires => {
                      'CAM::EmailTemplate'       => '0.90',
                      'Net::SMTP'                => '1.03',
                   },
                   build_requires => {
                      'Test::More'               => '0.01',
                   },
                   )->create_build_script;
