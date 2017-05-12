use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'Config::Wrest',
              VERSION_FROM  => 'lib/Config/Wrest.pm',
              PREREQ_PM => {
                             'Log::Trace' => 0,
                             'Test::Assertions' => 0,
                             'File::Slurp::WithinPolicy' => 0,
                             'Any::Template' => 0,
                             'Carp' => 0,
                             'Test::More' => 0,
                             'Getopt::Std' => 0,
                             'File::Basename' => 0,
                             'Data::Dumper' => 0,
                             'Cwd' => 0,
                           },
              ABSTRACT_FROM => 'lib/Config/Wrest.pm',
              AUTHOR        => 'British Broadcasting Corporation',
             );
