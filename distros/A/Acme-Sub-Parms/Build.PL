
use Module::Build;
my $build = Module::Build->new
      ( module_name    => 'Acme::Sub::Parms',
        dist_author    => 'Jerilyn Franz <cpan@jerilyn.info>',
        dist_abstract  => 'Function/Method parameter processing handlers',
        license        => 'mit',
        requires       => {
            'perl'              => '5.006',
            'warnings'          => 0,
            'Carp'              => 0,
            'Filter::Util::Call' => '1.06',
            },
        build_requires => { },
        test_requires       => {
            'perl'              => '5.006',
            'warnings'          => 0,
            'Carp'              => 0,
            'Filter::Util::Call' => '1.06',
            },
        meta_merge => {
          'meta-spec' => { version => 2 },
           resources => {
              bugtracker => {
                   web  => 'https://github.com/JerilynFranz/perl-Acme-Sub-Parms/issues',
               },
               homepage => 'https://github.com/JerilynFranz/perl-Acme-Sub-Parms',
               repository => {
                   type => 'git',
                   url  => 'https://github.com/JerilynFranz/perl-Acme-Sub-Parms.git',
                   web  => 'https://github.com/JerilynFranz/perl-Acme-Sub-Parms',
               },
            },
        },
      )->create_build_script;



