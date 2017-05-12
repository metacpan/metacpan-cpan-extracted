use ExtUtils::MakeMaker;
WriteMakefile(
            NAME => 'Bundle::Tie::DB_File::SplitHash',
    VERSION_FROM => 'lib/Bundle/Tie/DB_File/SplitHash.pm',
          'dist' => {
                COMPRESS => 'gzip -9f',
                  SUFFIX => '.gz', 
            DIST_DEFAULT => 'all tardist',
               },

);
