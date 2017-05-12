use Module::Build;

Module::Build->new
    ( module_name     => 'AnyDBM_File::Importer',
      dist_abstract   => 'Import DBM package symbols when using AnyDBM_File',
      perl            => 5.8,
      requires        => {
	                  'perl'              => 5.008,
	                  'AnyDBM_File'       => 0,
                         },
      build_requires  => {
	                  'Module::Build'     => 0,
                          'Test::More'        => 0,
			  'Test::Exception'   => 0,
			  'Test::Warn'        => 0

                         },
      create_makefile_pl
                      => 'passthrough',
      license         => 'perl',
    )->create_build_script;
