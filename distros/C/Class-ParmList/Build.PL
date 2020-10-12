
use Module::Build;
my $build = Module::Build->new
      ( module_name    => 'Class::ParmList',
        dist_author    => 'Jerilyn Franz <cpan@jerilyn.info>',
        dist_abstract  => 'Methods for processing named parameter lists',
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
            'Carp'              => 0,
            },
        meta_merge => {
          'meta-spec' => { version => 2 },
           resources => {
              bugtracker => {
                   web  => 'https://github.com/JerilynFranz/perl-Class-ParmList/issues',
               },
               homepage => 'https://github.com/JerilynFranz/perl-Class-ParmList',
               repository => {
                   type => 'git',
                   url  => 'https://github.com/JerilynFranz/perl-Class-ParmList.git',
                   web  => 'https://github.com/JerilynFranz/perl-Class-ParmList',
               },
            },
        },
      )->create_build_script;


