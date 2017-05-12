#!/usr/bin/perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

(my $extutils_numeric_version = $ExtUtils::MakeMaker::VERSION) =~ s/_.+$//;
WriteMakefile(
	NAME		=> 'Control::CLI::AvayaData',
	AUTHOR		=> q{Ludovico Stevens <lstevens@cpan.org>},
	VERSION_FROM	=> 'lib/Control/CLI/AvayaData.pm',
	ABSTRACT	=> 'Interact with CLI of Avaya Networking products over any of Telnet, SSH or Serial port',
	($extutils_numeric_version >= 6.3002
		? ('LICENSE'=> 'perl')
		: ()),
	PL_FILES	=> {},
	PREREQ_PM	=> {
		'Test::More'		=> 0,
		'Control::CLI'		=> 2.02,
	},
	BUILD_REQUIRES	=> {
		'Net::Telnet'		=> 0,
		'IO::Interactive'	=> 0,
	},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean		=> { FILES => 'Control-CLI-AvayaData-*' },
	MIN_PERL_VERSION => '5.6.0',
);
