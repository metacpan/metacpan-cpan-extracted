use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Apache::SMTP',
    VERSION_FROM      => 'lib/Apache/SMTP.pm', # finds $VERSION
    PREREQ_PM         => { Apache::TieBucketBrigade => '0.03',
                           Test::More => 0,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Apache/SMTP.pm', # retrieve abstract from module
       AUTHOR         => 'mock <mock@obscurity.org>') : ()),
);
