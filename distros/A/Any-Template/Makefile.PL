use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'Any::Template',
              VERSION_FROM  => 'lib/Any/Template.pm',
              PREREQ_PM => {
                              'Test::More' => 0,
                              'Test::Assertions' => 0,
                              'Log::Trace' => 0,
                              'File::Spec' => 0,
                           },
              ABSTRACT_FROM => 'lib/Any/Template.pm',
              AUTHOR        => 'British Broadcasting Corporation',
             );
