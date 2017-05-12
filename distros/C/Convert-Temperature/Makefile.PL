use 5.008008;
use ExtUtils::MakeMaker;

# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Convert::Temperature',
    VERSION_FROM      => 'lib/Convert/Temperature.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Convert/Temperature.pm', # retrieve abstract from module
       AUTHOR         => 'Filipe Dutra <mopy@cpan.org>') : ()),
);
