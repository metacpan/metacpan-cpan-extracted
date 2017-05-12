use 5.00503;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Acme::Terror::UK',
    VERSION_FROM      => 'lib/Acme/Terror/UK.pm', # finds $VERSION
    PREREQ_PM         => {
      'LWP::Simple'   => 5.48
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Acme/Terror/UK.pm', # retrieve abstract from module
       AUTHOR         => 'A. U. Thor <pricer@localdomain>') : ()),
);
