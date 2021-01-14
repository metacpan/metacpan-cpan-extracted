use 5.006002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AutoReloader',
    VERSION_FROM      => 'lib/AutoReloader.pm', # finds $VERSION
    PREREQ_PM         => { Scalar::Util => 1.0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AutoReloader.pm', # retrieve abstract from module
       AUTHOR         => 'shmem <shmem@cpan.org>') : ()),
);
