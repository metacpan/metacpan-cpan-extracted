use Module::Build;
my $build = Module::Build->new
      ( module_name    => 'CGI::Minimal',
        dist_author    => 'Jerilyn Franz <cpan@jerilyn.info>',
        dist_abstract  => 'A lightweight CGI form processing package',
        license        => 'mit',
        requires       => {
            'Carp' => 0,
        },

        build_requires => { },
        meta_merge => {
          'meta-spec' => { version => 2 },
           resources => {
              bugtracker => {
                   web  => 'https://github.com/JerilynFranz/perl-CGI-Minimal/issues',
               },
               homepage => 'https://github.com/JerilynFranz/perl-CGI-Minimal',
               repository => {
                   type => 'git',
                   url  => 'https://github.com/JerilynFranz/perl-CGI-Minimal.git',
                   web  => 'https://github.com/JerilynFranz/perl-CGI-Minimal',
               },
            },
        },
      )->create_build_script;
