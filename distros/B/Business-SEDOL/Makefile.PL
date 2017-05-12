use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  ( NAME         => 'Business::SEDOL',
    VERSION_FROM => 'SEDOL.pm',
    dist         => { COMPRESS => 'gzip',
                      SUFFIX   => 'gz',
                    },
);
