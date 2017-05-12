use Module::Build;
Module::Build->new(
                   module_name => 'CAM::SQLManager',
                   license => 'perl',
                   requires => {
                      'CAM::XML'                 => '0.25',
                      'DBI'                      => '1.0',  # tested on 1.201
                      'File::Spec'               => 0,
                   },
                   recommends => {
                      'XML::Xerces'              => '2.3.0',
                      'CGI'                      => '2.0',  # tested on 2.80
                   },
                   build_requires => {
                      'Test::More'               => '0.01',
                   },
                   )->create_build_script;
