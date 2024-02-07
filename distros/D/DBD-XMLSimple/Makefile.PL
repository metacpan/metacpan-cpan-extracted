#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

WriteMakefile(
    NAME		=> 'DBD::XMLSimple',
    AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM	=> 'lib/DBD/XMLSimple.pm',
    ABSTRACT_FROM       => 'lib/DBD/XMLSimple.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
    TEST_REQUIRES => {
	'Test::Most' => 0,
	'Test::Script' => 1.12,
	'Test::DatabaseRow' => 0,
	'Test::Differences' => 0,
	'Test::NoWarnings' => 0,
	'autodie' => 0,
	'IPC::System::Simple' => 0,
    },
    PREREQ_PM => {
	'XML::Twig' => 0,
	'SQL::Statement' => 1.410,
	'DBI::DBD::SqlEngine' => 0.06,
	'DBI' => 1.637,	# Version that understands XMLSimple impoer
	'Carp' => 0,
    },
    dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean		=> { FILES => 'DBD::XMLSimple-*' },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/DBD-XMLSimple.git',
				web => 'https://github.com/nigelhorne/DBD-XMLSimple',
				repository => 'https://github.com/nigelhorne/DBD-XMLSimple',
			}, bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=DBD-XMLSimple',
				web => 'https://github.com/nigelhorne/DBD-XMLSimple/issues',
				url => 'https://github.com/nigelhorne/DBD-XMLSimple/issues',
				mailto => 'bug-DBD-XMLSimple@rt.cpan.org'
			}
		},
	},
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
