use 5.012003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Compellent::CompCU',
    VERSION_FROM      => 'lib/Compellent/CompCU.pm', # finds $VERSION
    PREREQ_PM         => {'Lip::Pod'=>0,'IPC::Cmd'=>0.54}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Compellent/CompCU.pm', # retrieve abstract from module
       AUTHOR         => 'Adam Russell <ac.russell@live.com>') : ()),
);
