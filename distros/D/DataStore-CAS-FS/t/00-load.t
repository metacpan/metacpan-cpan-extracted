#! /usr/bin/env perl -T

use Test::More;
my @pkgs= qw(
	DataStore::CAS::FS
	DataStore::CAS::FS::Dir
	DataStore::CAS::FS::DirEnt
	DataStore::CAS::FS::DirCodec
	DataStore::CAS::FS::DirCodec::Minimal
	DataStore::CAS::FS::DirCodec::Universal
	DataStore::CAS::FS::DirCodec::Unix
	DataStore::CAS::FS::InvalidUTF8
	DataStore::CAS::FS::Importer
	DataStore::CAS::FS::Exporter
);

use_ok $_ or BAIL_OUT("use $_") for @pkgs;

diag "Testing on Perl $], $^X\n"
	.join('', map { sprintf("%-40s  %s\n", $_, $_->VERSION) } @pkgs);

done_testing;
