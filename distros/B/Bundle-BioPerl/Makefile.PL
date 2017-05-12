use ExtUtils::MakeMaker;
WriteMakefile(
              NAME	   => 'Bundle::BioPerl',
              VERSION_FROM => 'BioPerl.pm',
              'dist'       => {
                               COMPRESS => 'gzip -9f',
                               SUFFIX   => '.gz',
                               DIST_DEFAULT => 'all tardist',
                              },
             );
