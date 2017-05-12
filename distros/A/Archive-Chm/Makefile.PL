use 5.006004;
use Inline::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Archive::Chm',
    VERSION_FROM      => 'Chm.pm', # finds $VERSION
    PREREQ_PM         => {Inline::C => 0.44}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'Chm.pm', # retrieve abstract from module
       AUTHOR         => 'Alexandru Palade <apalde@netsoft.ro>') : ()),
);
