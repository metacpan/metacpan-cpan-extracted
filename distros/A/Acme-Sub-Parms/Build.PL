use Module::Build;
my $build = Module::Build->new
      ( module_name    => 'Acme::Sub::Parms',
        dist_author    => 'Benjamin Franz <snowhare@nihongo.org>',
        dist_abstract  => 'Function/Method parameter processing handlers',
        license        => 'perl',
        requires       => {
            'Carp'               => 0,
            'Filter::Util::Call' => '1.06',
        },
        build_requires => { },
      )->create_build_script;
