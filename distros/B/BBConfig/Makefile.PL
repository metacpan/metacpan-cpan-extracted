use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'BBConfig',
    VERSION_FROM      => 'lib/BoxBackup/Config/Accounts.pm', # finds $VERSION
    PREREQ_PM         => {'Config::Scoped' => '0.11'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'lib/BoxBackup/Config/Accounts.pm', # retrieve abstract from module
       AUTHOR         => 'Per Reedtz Thomsen <pthomsen@reedtz.com>') : ()),
);
