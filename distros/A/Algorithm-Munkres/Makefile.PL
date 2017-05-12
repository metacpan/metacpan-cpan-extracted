use 5.004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Algorithm::Munkres',
    VERSION_FROM      => 'lib/Algorithm/Munkres.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT  => 'Munkres.pm', # retrieve abstract from module
       AUTHOR         => 'Anagha Kulkarni <kulka020@d.umn.edu>, Ted Pedersen <tpederse@d.umn.edu>') : ()),
);
