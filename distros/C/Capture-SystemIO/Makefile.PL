use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Capture::SystemIO',
    VERSION_FROM      => 'lib/Capture/SystemIO.pm', # finds $VERSION
    PREREQ_PM         => {
	'Devel::StackTrace'		=> 1.16,
        'Class::Data::Inheritable'	=> 0.08,
        'Exception::Class'		=> 1.23,
	'Capture::Tiny'			=> 0.08,
    },
    ABSTRACT_FROM  =>'lib/Capture/SystemIO.pm', # retrieve abstract from module
    AUTHOR         => 'Rudolf Lippan <rlippan@remotelinux.com>',
);

