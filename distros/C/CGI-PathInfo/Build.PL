use Module::Build;

my $build = Module::Build->new
      ( module_name    => 'CGI::PathInfo',
        dist_author    => 'Jerilyn Franz <cpan@jerilyn.info>',
        dist_abstract  => 'A lightweight CGI processing package for using CGI PATH_INFO as if it were GET method form parameters',
        license        => 'mit',
        requires       => {
            'perl'     => '5.006',
            'warnings' => 0,
            'Carp'     => 0,
            'HTML::Entities' => 0,
        },
        build_requires => { },
        test_requires => {
            'perl'           => '5.006',
            'warnings'       => 0,
            'Carp'           => 0,
            'HTML::Entities' => 0,
        },
        meta_merge => {
          'meta-spec' => { version => 2 },
           resources => {
              bugtracker => {
                   web  => 'https://github.com/JerilynFranz/perl-CGI-PathInfo/issues',
               },
               homepage => 'https://github.com/JerilynFranz/perl-CGI-PathInfo',
               repository => {
                   type => 'git',
                   url  => 'https://github.com/JerilynFranz/perl-CGI-PathInfo.git',
                   web  => 'https://github.com/JerilynFranz/perl-CGI-PathInfo',
               },
            },
        },
      )->create_build_script;
