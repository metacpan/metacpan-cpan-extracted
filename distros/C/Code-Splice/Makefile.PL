use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Code::Splice',
    VERSION_FROM      => 'lib/Code/Splice.pm', # finds $VERSION
    PREREQ_PM         => { B::Generate => 0.1, }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Code/Splice.pm', # retrieve abstract from module
       AUTHOR         => 'Scott Walters <scott@slowass.net>') : ()),
);
