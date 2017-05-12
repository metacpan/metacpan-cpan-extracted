use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'        => 'Crypt::GOST_PP',
    'VERSION_FROM'    => 'GOST_PP.pm', # finds $VERSION
    'PREREQ_PM'        => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'GOST_PP.pm', # retrieve abstract from module
       AUTHOR     => 'Kurt Kincaid <sifukurt@yahoo.com>') : ()),
);
