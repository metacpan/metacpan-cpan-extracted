use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AnyEvent::AggressiveIdle',
    VERSION_FROM      => 'lib/AnyEvent/AggressiveIdle.pm', # finds $VERSION
    PREREQ_PM         => {
        AnyEvent        => 0,	
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AnyEvent/AggressiveIdle.pm', # retrieve abstract from module
       AUTHOR         => 'Dmitry E. Oboukhov <dimka@>') : ()),
);
