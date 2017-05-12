use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'App::sh2p',
    VERSION_FROM      => 'bin/sh2p.pl', # finds $VERSION
    PREREQ_PM         => { Getopt::Std => 1.0, File::Basename => 1.0 }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/App/sh2p.pod', # retrieve abstract from module
       AUTHOR         => 'C. B. Darke <clive.darke@talk21.com>') : ()),
       'EXE_FILES'    => ['bin/sh2p.pl'],
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'

);
