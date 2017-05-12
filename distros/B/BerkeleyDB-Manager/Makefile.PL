#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

my $checked_bdb;

if ( eval { require BerkeleyDB } ) {
    do "check_bdb_version.PL";
	die $@ if $@;
    $checked_bdb++;
}

WriteMakefile(
	NAME         => 'BerkeleyDB::Manager',
	VERSION_FROM => 'lib/BerkeleyDB/Manager.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
    PL_FILES     => { $checked_bdb ? () : ( "check_bdb_version.PL" => "check_bdb_version" ) },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
		'Test::TempDir' => 0.04,
		'Test::Exception' => 0,
		'Moose' => 0,
		'namespace::clean' => '0.08',
		'BerkeleyDB' => '0.36',
		'Data::Stream::Bulk' => 0.03,
		'Path::Class' => 0,
	},
);

