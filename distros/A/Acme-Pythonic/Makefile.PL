use 5.006_001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Acme::Pythonic',
    VERSION_FROM      => 'lib/Acme/Pythonic.pm', # finds $VERSION
    # These versions are the lowest ones I've test the module with.
    PREREQ_PM         => {'Test::More'          => '0.45',
                          'Filter::Simple'      => '0.78',
                          'Text::Tabs'          => '98.112801',
                          },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Acme/Pythonic.pm', # retrieve abstract from module
       AUTHOR         => 'Xavier Noria (FXN)') : ()),
);
