use Module::Build;

Module::Build->new( module_name => 'Class::AlzaboWrapper',
                    license  => 'perl',
                    requires => { 'Alzabo' => 0,
                                  'Exception::Class' => 0,
                                  'Params::Validate' => 0,
                                  'Test::More' => 0,
                                },
                    build_requires => { 'Module::Build' => 0 },
                    sign     => 1,
                    create_makefile_pl => 'passthrough',
                    create_readme => 1,
                  )->create_build_script;
