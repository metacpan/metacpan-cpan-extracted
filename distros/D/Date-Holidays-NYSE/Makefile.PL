use ExtUtils::MakeMaker;
WriteMakefile(
    NAME            => 'Date::Holidays::NYSE',
    VERSION_FROM    => 'lib/Date/Holidays/NYSE.pm',
    PREREQ_PM       => {
                        'POSIX'      => 0,
                        'Exporter'   => 0,
                        'Date::Calc' => 5.0, #for Add_Delta_Days
                       },
    ABSTRACT_FROM  => 'lib/Date/Holidays/NYSE.pm',
    AUTHOR         => 'Michael R. Davis',
    LICENSE        => 'MIT',
    'META_MERGE'   => {
                       'meta-spec' => {
                                       'version' => 2
                                      },
                       'resources' => {
                                       'repository' => {
                                                        'web'  => 'https://github.com/mrdvt92/perl-Date-Holidays-NYSE.git',
                                                        'url'  => 'git@github.com:mrdvt92/perl-Date-Holidays-NYSE.git',
                                                        'type' => 'git'
                                                       },
                                       'homepage'   => 'https://github.com/mrdvt92/perl-Date-Holidays-NYSE',
                                       'bugtracker' => {
                                                        'web' => 'https://github.com/mrdvt92/perl-Date-Holidays-NYSE/issues'
                                                       }
                                      },
                      }

);
