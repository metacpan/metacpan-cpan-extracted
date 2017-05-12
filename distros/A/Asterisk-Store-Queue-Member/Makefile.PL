use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Asterisk::Store::Queue::Member',
    VERSION_FROM      => 'lib/Asterisk/Store/Queue/Member.pm', # finds $VERSION
    PREREQ_PM         => { 'Log::Log4perl' => 0,
	                   'Log::Dispatch::Screen' => 0,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Asterisk/Store/Queue/Member.pm', # retrieve abstract from module
       AUTHOR         => 'Derek Carter <goozbach@neverblock.com>') : ()),
);
