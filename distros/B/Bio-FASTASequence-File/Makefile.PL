use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Bio::FASTASequence::File',
    VERSION_FROM      => 'lib/Bio/FASTASequence/File.pm', # finds $VERSION
    PREREQ_PM         => {
            Bio::FASTASequence => 0.03,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Bio/FASTASequence/File.pm', # retrieve abstract from module
       AUTHOR         => 'Renee Baecker <module@renee-baecker.de>') : ()),
);
