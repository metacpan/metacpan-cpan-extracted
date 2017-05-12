use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Bundle::WormBase',
    VERSION_FROM      => 'WormBase.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'WormBase.pm',
       AUTHOR         => 'Todd Harris <harris@cshl.edu>') : ()
    ),
#   'dist'       => {
#                         COMPRESS => 'gzip -9f',
#                         SUFFIX   => '.gz',
#                         DIST_DEFAULT => 'all tardist',
#                              },
);
