use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Bundle::Pugs::SmokeKit',
    VERSION_FROM      => 'lib/Bundle/Pugs/SmokeKit.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Bundle/Pugs/SmokeKit.pm', # retrieve abstract from module
       AUTHOR         => 'Gaal Yahas <gaal@forum2.org>') : ()),
);

warn <<".";

*** Bundle::Pugs::SmokeKit has been obsoleted by Task::Smoke.
    Please install that instead.

.
