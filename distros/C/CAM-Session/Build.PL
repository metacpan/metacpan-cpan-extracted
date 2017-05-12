use Module::Build;
Module::Build->new(
                   module_name => 'CAM::Session',
                   license => 'perl',
                   requires => {
                      'CGI'                      => '2.0',
                      'CGI::Cookie'              => '1.0',
                      'DBI'                      => '1.0',
                      'Digest::MD5'              => '2.0',
                   },
                   build_requires => {
                      'Test::More'               => '0.01',
                      'DBD::mysql'               => '0.01',
                   },
                   )->create_build_script;
