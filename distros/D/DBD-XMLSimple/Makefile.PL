#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec 3.4;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
    NAME		=> 'DBD::XMLSimple',
    AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
    VERSION_FROM	=> 'lib/DBD/XMLSimple.pm',
    ABSTRACT_FROM       => 'lib/DBD/XMLSimple.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
    PREREQ_PM => {
	'XML::Twig' => 0,
	'SQL::Statement' => 1.410,
	'DBI::DBD::SqlEngine' => 0.06,
	DBI => 1.643	# Version that understands XMLSimple import
    }, TEST_REQUIRES => {
	'Carp' => 0,
	'File::Slurp' => 0,
	'File::Temp' => 0,
	'POSIX' => 0,
	'Readonly' => 0,
	'Test::Most' => 0,
	'Test::Script' => 1.12,
	'Test::DatabaseRow' => 0,
	'Test::DescribeMe' => 0,
	'Test::Differences' => 0,
	'Test::NoWarnings' => 0,
	'Test::Needs' => 0,
	'autodie' => 0,
	'IPC::System::Simple' => 0,
    }, dist => $dist,
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
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=DBD-XMLSimple',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=DBD-XMLSimple',
				# web => 'https://github.com/nigelhorne/DBD-XMLSimple/issues',
				# url => 'https://github.com/nigelhorne/DBD-XMLSimple/issues',
				mailto => 'bug-DBD-XMLSimple@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
