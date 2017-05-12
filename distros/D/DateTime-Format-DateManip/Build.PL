use Module::Build;

Module::Build->new
    ( module_name  => 'DateTime::Format::DateManip',
      author       => 'Ben Bennett <fiji@limey.net>',
      license      => 'perl',

      requires     => { 'DateTime'                           => 0,
      			'Date::Manip'                        => 0,
			'Test::More'                         => 0,
			'Carp'                               => 0,
                      },
    )->create_build_script;
