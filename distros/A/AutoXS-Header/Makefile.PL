use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AutoXS::Header',
    VERSION_FROM      => 'lib/AutoXS/Header.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    LICENSE => 'perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AutoXS/Header.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
);
