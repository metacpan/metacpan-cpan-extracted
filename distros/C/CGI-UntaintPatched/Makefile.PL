use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::UntaintPatched',
    VERSION_FROM      => 'lib/CGI/UntaintPatched.pm', # finds $VERSION
    PREREQ_PM         => {CGI::Untaint => 1.24}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CGI/UntaintPatched.pm', # retrieve abstract from module
       AUTHOR         => 'Peter Speltz <peter@suse.de>') : ()),
);
