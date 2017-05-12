use ExtUtils::MakeMaker;
WriteMakefile(
            NAME => 'Bundle::Search::InvertedIndex',
    VERSION_FROM => 'lib/Bundle/Search/InvertedIndex.pm',
          'dist' => {
              COMPRESS => 'gzip -9f',
                SUFFIX => '.gz', 
          DIST_DEFAULT => 'all tardist',
               },

);
