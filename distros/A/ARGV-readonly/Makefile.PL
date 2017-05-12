use 5.00001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ARGV::readonly',
    VERSION_FROM      => 'lib/ARGV/readonly.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/ARGV/readonly.pm', # retrieve abstract from module
       AUTHOR         => 'David Nicol <davidnico@cpan.org>') : ()),
);
