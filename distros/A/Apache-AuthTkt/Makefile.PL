use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Apache::AuthTkt',
    VERSION_FROM      => 'AuthTkt.pm', # finds $VERSION
    PREREQ_PM         => {
        Carp => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'AuthTkt.pm', # retrieve abstract from module
       AUTHOR         => 'Gavin Carr <gavin@openfusion.com.au>') : ()),
);
# arch-tag: ce3a678b-23f9-4a94-a069-b25b9ad0be7a
