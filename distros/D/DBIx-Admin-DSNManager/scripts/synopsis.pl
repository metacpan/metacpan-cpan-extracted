#!/usr/bin/env perl

use strict;
use warnings;

use DBIx::Admin::DSNManager;

use Try::Tiny;

# --------------------------

try
{
	my($man1) = DBIx::Admin::DSNManager -> new
	(
		config  => {'Pg.1' => {dsn => 'dbi:Pg:dbname=test', username => 'me', active => 1} },
		verbose => 1,
	);

	my($file_name) = '/tmp/dsn.ini';

	$man1 -> write($file_name);

	my($man2) = DBIx::Admin::DSNManager -> new
	(
		file_name => $file_name,
		verbose   => 1,
	);

	$man2 -> report;
}
catch
{
	print "DBIx::Admin::DSNManager died. Error: $_";
};
