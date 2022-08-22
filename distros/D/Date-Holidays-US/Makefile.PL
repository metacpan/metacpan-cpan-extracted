use ExtUtils::MakeMaker;
WriteMakefile(
    NAME            => 'Date::Holidays::US',
    VERSION_FROM    => 'lib/Date/Holidays/US.pm',
    PREREQ_PM       => {
                        POSIX    => 0,
                        Exporter => 0,
                       },
    ABSTRACT_FROM  => 'lib/Date/Holidays/US.pm',
    AUTHOR         => 'Michael R. Davis',
    'META_MERGE'   => {
                       'meta-spec' => {
                                       'version' => 2
                                      },
                       'resources' => {
                                       'repository' => {
                                                        'web'  => 'https://github.com/mrdvt92/perl-Date-Holidays-US.git',
                                                        'url'  => 'git@github.com:mrdvt92/perl-Date-Holidays-US.git',
                                                        'type' => 'git'
                                                       },
                                       'homepage'   => 'https://github.com/mrdvt92/perl-Date-Holidays-US',
                                       'bugtracker' => {
                                                        'web' => 'https://github.com/mrdvt92/perl-Date-Holidays-US/issues'
                                                       }
                                      },
                      }

);
