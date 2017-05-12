use ExtUtils::MakeMaker;

WriteMakefile (
               AUTHOR        => 'Casey West <casey@geeknest.com>',
               ABSTRACT      => "Provide Globally Unique Column Values",
               NAME          => 'Class::DBI::UUID',
               PREREQ_PM     => {
                                 'Class::DBI' => '0.96',
                                 'Data::UUID' => '0.11',
                                 'Test::More' => '0.47',
                                },
               VERSION_FROM  => 'lib/Class/DBI/UUID.pm',
              );
