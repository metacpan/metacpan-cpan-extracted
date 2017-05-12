use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Business::3DSecure',
    VERSION_FROM      => 'lib/Business/3DSecure.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Business/3DSecure.pm', # retrieve abstract from module
       AUTHOR         => 'Clayton Cottingham <clayton@wintermarket.net>') : ()),
);
