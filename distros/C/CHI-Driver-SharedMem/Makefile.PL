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
    BUILD_REQUIRES => {
	'Test::Most' => 0,
	'Test::NoWarnings' => 0,
	'Test::Warn' => 0,
	'Test::Class' => 0,
	'CHI::Test' => 0,
	'CHI::Test::Util' => 0,
	'Date::Parse' => 0,	# Used by CHI::Test but not a prereq of it
	# 'Test::Kwalitee' => 0,
	'Test::Requires' => 0,
    }, PREREQ_PM => {
	'JSON::MaybeXS' => 0,
	'Moose' => 0,
	'IPC::SysV' => 0,
	'IPC::SharedMem' => 0,
	'CHI' => 0.54,	# Needs latest CHI::Stats
	'Config' => 0,
	'Fcntl' => 0,
    }, TEST_REQUIRES => {
	'Test::Carp' => 0,
	},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CHI-Driver-SharedMem-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
	resources => {
		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/CHI-Driver-SharedMem.git',
			web => 'https://github.com/nigelhorne/CHI-Driver-SharedMem',
		}, bugtracker => {
			# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=CHI-Driver-SharedMem',
			# mailto => 'bug-CHI-Driver-SharedMem@rt.cpan.org'
			web => 'https://github.com/nigelhorne/CHI-Driver-SharedMem/issues',
			url => 'https://github.com/nigelhorne/CHI-Driver-SharedMem/issues',
		}

	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
