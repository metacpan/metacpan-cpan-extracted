use 5.00000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'AMF::Perl',
    'VERSION_FROM'	=> 'lib/AMF/Perl.pm', # finds $VERSION
    'PREREQ_PM'		=> {Exception::Class => 0.01, DBI => 0.01, Encode => 0.01}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/AMF/Perl.pm', # retrieve abstract from module
       AUTHOR     => 'Vsevolod (Simon) Ilyushchenko <simonf@simonf.com>') : ()),
);
