use ExtUtils::MakeMaker;

require 5.005_62;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
 ($] ge '5.005') ?
 (
  AUTHOR   => 'Ron Savage (ron@savage.net.au)',
  ABSTRACT => 'Back-up all tables in a db to XML, and restore them',
 ) : (),
 clean =>
 {
	 FILES => 'blib/* Makefile MANIFEST DBIx-Admin-BackupRestore-*'
 },
 dist =>
 {
	COMPRESS => 'gzip',
	SUFFIX   => 'gz'
 },
 DISTNAME  => 'DBIx-Admin-BackupRestore',
 NAME      => 'DBIx::Admin::BackupRestore',
 PL_FILES  => {},
 PREREQ_PM =>
 {
	 Carp            => 0,
	 Test::More      => 0,
	 XML::Parser     => 0,
	 XML::Records    => 0,
	 XML::TokeParser => 0,
 },
 VERSION_FROM => 'lib/DBIx/Admin/BackupRestore.pm',
);
