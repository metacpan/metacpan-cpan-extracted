use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  ( NAME         => 'Business::CUSIP',
    VERSION_FROM => 'CUSIP.pm',
    PREREQ_PM    => { Algorithm::LUHN => 0,
                    },
    dist         => { COMPRESS => 'gzip',
                      SUFFIX   => 'gz',
                    },
);
