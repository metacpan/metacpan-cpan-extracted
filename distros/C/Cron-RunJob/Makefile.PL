use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Cron::RunJob',
    VERSION_FROM      => 'lib/Cron/RunJob.pm', # finds $VERSION
    PREREQ_PM         => {'Mail::Mailer'=>1}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Cron/RunJob.pm', # retrieve abstract from module
       AUTHOR         => 'Kiel Stirling <kielstr@>cpan.org') : ()),
);
