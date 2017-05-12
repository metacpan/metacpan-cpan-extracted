use Module::Build;
my $build = Module::Build->new
      ( module_name    => 'Class::ParmList',
        dist_author    => 'Benjamin Franz <snowhare@nihongo.org>',
        dist_abstract  => 'Methods for processing named parameter lists',
        license        => 'perl',
        requires       => {},
        build_requires => {},
      )->create_build_script;
