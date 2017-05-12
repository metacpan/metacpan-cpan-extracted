use Module::Build;

Module::Build->new
    ( module_name  => 'DateTime::Format::ICal',
      author       => 'Dave Rolsky <autarch@urth.org>',
      license      => 'perl',

      requires     => { 'DateTime' => 0.17,
                        'DateTime::Event::ICal' => 0.03,
                        'DateTime::Set' => 0.10, # really want DT::Span in same distro
                        'DateTime::TimeZone' => 0.22,
                        'Params::Validate' => 0.59,
                      },
      build_requires => { 'Module::Build' => 0 },
    )->create_build_script;
