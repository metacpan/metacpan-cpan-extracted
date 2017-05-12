use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::RoundRobinShared',
    VERSION_FROM      => 'lib/Data/RoundRobinShared.pm', # finds $VERSION
    PREREQ_PM         => {IPC::Shareable => 0.6}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/RoundRobinShared.pm', # retrieve abstract from module
       AUTHOR         => 'S Pradeep <pradeep@pradeep.net.in>') : ()),
);
