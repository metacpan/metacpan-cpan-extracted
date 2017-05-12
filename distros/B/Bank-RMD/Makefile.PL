use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Bank::RMD',
    VERSION_FROM      => 'lib/Bank/RMD.pm', # finds $VERSION
    PREREQ_PM         => {
			DateTime => 0.20
			}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Bank/RMD.pm', # retrieve abstract from module
       AUTHOR         => 'Tyler Hardison <tyler@seraph-net.net>') : ()),
);
