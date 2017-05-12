use strict;
use warnings;
use ExtUtils::MakeMaker;

if($^O eq 'MSWin32') {
	# This will set the CPAN-Testers status to Unknown
	# TODO: Work out how to set the status to NA
	die 'Windows is not supported';
} elsif($^O eq 'gnu') {
	# I don't believe that the hurd supports shared memory
	die 'GNU/Hurd is not supported';
}

WriteMakefile(
    NAME                => 'CHI::Driver::SharedMem',
    AUTHOR              => q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM        => 'lib/CHI/Driver/SharedMem.pm',
    ABSTRACT_FROM       => 'lib/CHI/Driver/SharedMem.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::Most' => 0,
	'Test::NoWarnings' => 0,
	'Test::Warn' => 0,
	'Test::Class' => 0,
	'Storable' => 0,
	'Moose' => 0,
	'IPC::SysV' => 0,
	'IPC::SharedMem' => 0,
	'CHI' => 0.54,	# Needs latest CHI::Stats
	'CHI::Test' => 0,
	'CHI::Test::Util' => 0,
	'Config' => 0,
	'Fcntl' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CHI-Driver-SharedMem-*' },
);
