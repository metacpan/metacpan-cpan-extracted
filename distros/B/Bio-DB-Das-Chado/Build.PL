use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'Bio::DB::Das::Chado',
      all_from        => 'lib/Bio/DB/Das/Chado.pm',
      license         => 'perl',
      requires        => {
                           'Bio::Root::Version' => '1.006',
                           'DBI'                => '0',
                           'DBD::Pg'            => '0',
                           'URI::Escape'        => '0',
                         },
      recommends      => {
                           'Bio::GMOD::DB::Config' => '1.22',
                         },
    )->create_build_script;
