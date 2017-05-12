use Module::Build;
my $build = Module::Build->new
      ( module_name    => 'Class::NamedParms',
        dist_author    => 'Benjamin Franz <snowhare@nihongo.org>',
        dist_abstract  => 'A lightweight base class for checked get/set property accessors',
        license        => 'perl',
        requires       => {
            'Carp' => 0,
        },
        build_requires => {},
      )->create_build_script;
