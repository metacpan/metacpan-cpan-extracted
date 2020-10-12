use Module::Build;
my $build = Module::Build->new
      ( module_name    => 'Class::NamedParms',
        dist_author    => 'Jerilyn Franz <cpan@jerilyn.info>',
        dist_abstract  => 'A lightweight base class for checked get/set property accessors',
        license        => 'mit',
        requires       => {
            'perl'              => '5.006',
            'warnings'          => 0,
            'Carp'              => 0,
            },
        build_requires => { },
        test_requires       => {
            'perl'              => '5.006',
            'warnings'          => 0,
            'Test::More'        => 0,
            },
        meta_merge => {
          'meta-spec' => { version => 2 },
           resources => {
              bugtracker => {
                   web  => 'https://github.com/JerilynFranz/perl-Class-NamedParms/issues',
               },
               homepage => 'https://github.com/JerilynFranz/perl-Class-NamedParms',
               repository => {
                   type => 'git',
                   url  => 'https://github.com/JerilynFranz/perl-Class-NamedParms.git',
                   web  => 'https://github.com/JerilynFranz/perl-Class-NamedParms',
               },
            },
        },
      )->create_build_script;

