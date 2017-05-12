use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'Cache::AgainstFile',
              VERSION_FROM  => 'lib/Cache/AgainstFile.pm',
              PREREQ_PM => {
                            Test::Assertions => 0,
                            Log::Trace => 0,
                            Storable => 0,
                            File::Spec::Functions => 0,
                           },
              ABSTRACT_FROM => 'lib/Cache/AgainstFile.pm',
              AUTHOR        => 'British Broadcasting Corporation',
             );
