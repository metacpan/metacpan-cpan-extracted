#!/usr/bin/perl
#
# Name:
#	backup-db.pl.

use strict;
use warnings;

use DBI;
use DBIx::Admin::BackupRestore;

# -----------------------------------------------

my($file_name)	= shift || die("Usage: perl backup-db.pl backup-db.xml");
my($driver)		= ($^O eq 'MSWin32') ? 'mysql' : 'Pg';
my($dsn)		= ($driver eq 'mysql') ? 'dbi:mysql:db_name' : 'dbi:Pg:dbname=db_name';
my($username)	= ($driver eq 'mysql') ? 'root' : 'postgres';
my($password)	= ($driver eq 'mysql') ? 'pass' : '';
my($dbh)		= DBI -> connect
(
	$dsn, $username, $password,
	{
		AutoCommit			=> 1,
		FetchHashKeyName	=> 'NAME_lc',
		HandleError			=> sub {Error::Simple -> record($_[0]); 0},
		PrintError			=> 0,
		RaiseError			=> 1,
		ShowErrorStatement	=> 1,
	}
);

open(OUT, "> $file_name") || die("Can't open(> $file_name): $!");
print OUT DBIx::Admin::BackupRestore -> new
(
	clean		=> 1,
	dbh			=> $dbh,
	skip_tables	=>
	[	# For exporting from MS Access only.
		qw/msysaces msysaccessobjects msyscolumns msysimexcolumns msysimexspecs msysindexes msysmacros msysmodules2 msysmodules msysobjects msysqueries msysrelationships/
	],
	verbose => 1,
) -> backup('db_name');
close OUT;
