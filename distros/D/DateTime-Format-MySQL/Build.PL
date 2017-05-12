use Module::Build;

Module::Build->new
    ( module_name  => 'DateTime::Format::MySQL',
      author       => 'Dave Rolsky <autarch@urth.org>',
      license      => 'perl',

      requires     => { 'DateTime' => 0,
                        'DateTime::Format::Builder' => 0.60,
                      },
      build_requires => { 'Module::Build' => 0 },
      sign         => 1,
      create_makefile_pl => 'passthrough',
    )->create_build_script;
