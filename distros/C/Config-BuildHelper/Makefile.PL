use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Config::BuildHelper',
    VERSION_FROM      => 'lib/Config/BuildHelper.pm', # finds $VERSION
    PREREQ_PM         => { Data::Classifier => undef }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Config/BuildHelper.pm', # retrieve abstract from module
       AUTHOR         => 'A. U. Thor <triddle@localdomain>') : ()),
);
