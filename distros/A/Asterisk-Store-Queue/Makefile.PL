use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Asterisk::Store::Queue',
    VERSION_FROM      => 'lib/Asterisk/Store/Queue.pm', # finds $VERSION
    PREREQ_PM         => {
	    		   'Asterisk::Store::Queue::Member' => 0,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Asterisk/Store/Queue.pm', # retrieve abstract from module
       AUTHOR         => 'Derek Carter <goozbach@neverblock.com>') : ()),
);
