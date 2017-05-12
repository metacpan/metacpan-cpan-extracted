use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Convert::Transcribe',
    'VERSION_FROM'	=> 'Transcribe.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Transcribe.pm', # retrieve abstract from module
       AUTHOR     => 'Thomas M. Widmann <thomas@widmann.uklinux.net>') : ()),
);
