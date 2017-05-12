use Module::Build;
my $build = Module::Build->new (
                                 sign => 1, 
                                 module_name => 'Class::DBI::Loader::Informix',
                                 license  => 'perl',
                                 version  => '1.4',
            requires => {
                         'perl'          => '5.6.1',
                          Test::More     => 0.32,
                          DBD::Informix  => 2005.02,
                          Class::DBI     => 0.89,
                          Class::DBI::Loader => 0.29

                        },
           );
         $build->create_build_script;

