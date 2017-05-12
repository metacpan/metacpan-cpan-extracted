use Module::Build;
Module::Build->new(
                   module_name => 'CAM::Template::Cache',
                   license => 'perl',
                   requires => {
                      'CAM::Template'            => '0.90',
                      'DBI'                      => '1.00', # tested on 1.201
                   },
                   recommends => {
                   },
                   build_requires => {
                      'Test::More'               => '0.01',
                   },
                   )->create_build_script;
