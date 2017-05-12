use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::Classifier',
    VERSION_FROM      => 'lib/Data/Classifier.pm', # finds $VERSION
    PREREQ_PM         => {YAML => undef }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/Classifier.pm', # retrieve abstract from module
       AUTHOR         => 'Tyler Riddle <triddle@gmail.com>') : ()),
);
