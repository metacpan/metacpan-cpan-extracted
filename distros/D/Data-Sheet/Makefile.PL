use 5.012001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::Sheet',
    VERSION_FROM      => 'lib/Data/Sheet.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/Sheet.pm', # retrieve abstract from module
       AUTHOR         => 'Pocket <poketo7878@yahoo.co.jp>') : ()),
);
