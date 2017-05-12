use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Daemon::Simple',
    VERSION_FROM      => 'lib/Daemon/Simple.pm', # finds $VERSION
    PREREQ_PM         => {Proc::ProcessTable=>0.41,File::Spec=>3.25}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Daemon/Simple.pm', # retrieve abstract from module
       AUTHOR         => 'HyeonSeung Kim <sng2nara@hanmail.net>') : ()),
);
