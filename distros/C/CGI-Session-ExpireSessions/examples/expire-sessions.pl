#!/usr/bin/env perl

use strict;
use warnings;

use CGI::Session::ExpireSessions;
use DBI;

# -----------------------------------------------

my($dbh) = DBI -> connect
(
	'DBI:mysql:aussi:127.0.0.1',
	'root',
	'pass',
	{
		AutoCommit			=> 1,
		PrintError			=> 0,
		RaiseError			=> 1,
		ShowErrorStatement	=> 1,
	}
);

CGI::Session::ExpireSessions -> new(dbh => $dbh, verbose => 1) -> expire_db_sessions();
CGI::Session::ExpireSessions -> new(temp_dir => '/temp', verbose => 1) -> expire_file_sessions();
