use ExtUtils::MakeMaker;

WriteMakefile (
               AUTHOR        => 'Casey West <casey@geeknest.com>',
               ABSTRACT      => "Format CDBI Objects as XML",
               NAME          => 'Class::DBI::AsXML',
               PREREQ_PM     => {
                                 'Class::DBI' => '0.96',
                                 'Test::More' => '0.47',
                                 'XML::Simple' => '2.09',
                                },
               VERSION_FROM  => 'lib/Class/DBI/AsXML.pm',
              );
