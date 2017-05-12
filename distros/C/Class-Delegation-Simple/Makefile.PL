
use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::Delegation::Simple',
    VERSION_FROM      => 'lib/Class/Delegation/Simple.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    dist => {
      PREOP => 'pod2text lib/Class/Delegation/Simple.pm > $(DISTVNAME)/README',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Class/Delegation/Simple.pm', # retrieve abstract from module
       AUTHOR         => 'John Drago <jdrago_999@yahoo.com>') : ()),
);
