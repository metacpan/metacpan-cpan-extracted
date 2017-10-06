use 5.010001;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Crypt::Cisco',
    VERSION_FROM      => 'lib/Crypt/Cisco.pm', # finds $VERSION
    ($ExtUtils::MakeMaker::VERSION >= 6.3002) ? ('LICENSE'  => 'perl', ) : (),
    EXE_FILES         => ['bin/cisco-pass.pl',],
    PREREQ_PM         => {Test::Simple => 0, }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Crypt/Cisco.pm', # retrieve abstract from module
       AUTHOR         => 'Michael Vincent <vin at vinsworld dot com>') : ()),
);
