use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'           => 'CGI::Minimal',
    'VERSION_FROM'   => 'lib/CGI/Minimal.pm',
    'dist'           => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
                     'ZIP'=>'/usr/bin/zip','ZIPFLAGS'=>'-rl'},
    'PREREQ_PM'      => {
                            'Carp' => 0,
    }, 
    META_MERGE => {
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
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CGI/Minimal.pod', # retrieve abstract from module
       AUTHOR         => 'Jerilyn Franz <cpan@jerilyn.info>') : ()),

       PL_FILES       => {},
);
