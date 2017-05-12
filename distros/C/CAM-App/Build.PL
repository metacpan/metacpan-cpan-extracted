use Module::Build;
Module::Build->new(
                   module_name => 'CAM::App',
                   license => 'perl',
                   requires => {
                      'CGI'                      => '2.00',
                      'CAM::Template'            => 0,
                      'File::Spec'               => 0,
                   },
                   recommends => {
                      'CGI::Cookie'              => '1.00',
                      'CGI::Compress::Gzip'      => 0,
                      'DBI'                      => '1.10',
                      'CAM::Session'             => 0,
                      'CAM::SQLManager'          => 0,
                      'CAM::SQLObject'           => 0,
                      'CAM::EmailTemplate'       => 0,
                      'CAM::EmailTemplate::SMTP' => 0,
                      'CAM::Template::Cache'     => 0,
                   },
                   build_requires => {
                      'Test::More'               => 0,
                   },
                   )->create_build_script;
