use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Alvis::Saa',
    VERSION_FROM      => 'lib/Alvis/Saa.pm', # finds $VERSION
    PREREQ_PM         => {IO::Socket => 0,Data::Dumper => 0,Sys::Hostname => 0,IO::Select => 0,
                          Fcntl => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Alvis/Saa.pm', # retrieve abstract from module
       AUTHOR         => 'Antti Tuominen,<antti.tuominen@hiit.fi>, Kimmo Valtonen <kimmo.valtonen@hiit.fi>') : ()),

);
