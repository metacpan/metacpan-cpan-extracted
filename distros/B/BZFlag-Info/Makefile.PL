use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'BZFlag::Info',
    'VERSION_FROM'	=> 'Info.pm', # finds $VERSION
    'PREREQ_PM'		=> {LWP::UserAgent => 0, Socket => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Info.pm', # retrieve abstract from module
       AUTHOR     => 'Tucker McLean <tuckerm@noodleroni.com>') : ()),
);
