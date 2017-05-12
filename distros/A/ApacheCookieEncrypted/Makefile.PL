use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::Cookie::Encrypted',
    'VERSION_FROM'	=> 'Encrypted.pm', # finds $VERSION
    'PREREQ_PM'		=> { Crypt::CBC => 1.25, Crypt::Blowfish => 2.06, Apache::Cookie => 0.01 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Encrypted.pm', # retrieve abstract from module
       AUTHOR     => 'Jamie Krasnoo <jkrasnoo@socal.rr.com>') : ()),
);
