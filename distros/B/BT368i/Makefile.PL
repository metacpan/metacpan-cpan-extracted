use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'BT368i',
    VERSION_FROM      => 'lib/BT368i.pm', # finds $VERSION
    PREREQ_PM         => {
			Device::SerialPort => '0',
			RingBuffer         => '0',
		}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/BT368i.pm', # retrieve abstract from module
       AUTHOR         => 'Travis Kent Beste <travis@tencorners.com>') : ()),
);
