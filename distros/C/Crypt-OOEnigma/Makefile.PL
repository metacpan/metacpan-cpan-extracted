use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Crypt::OOEnigma',
    'VERSION_FROM'	=> 'lib/Crypt/OOEnigma.pm', # finds $VERSION
    'PREREQ_PM'		=> {Storable => 0.6.1.11, Test::More => 0.41}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM => 'Crypt/OOEnigma.pm', # retrieve abstract from module
       AUTHOR     => 'S J Baker <sjb@ambrielconsulting.com>') : ()),
);
