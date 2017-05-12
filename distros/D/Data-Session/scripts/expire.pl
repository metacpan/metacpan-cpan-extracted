#!/usr/bin/env perl

use lib 't';
use strict;
use warnings;

use Data::Session;

use DBI;

use File::Spec;
use File::Temp;

use Test;

# -----------------------------------------------

# The EXLOCK is for BSD-based systems.

my($directory)   = File::Temp::newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
my($data_source) = 'dbi:SQLite:dbname=' . File::Spec -> catdir($directory, 'sessions.sqlite');
my($type)        = 'driver:SQLite;id:MD5;serialize:DataDumper';
my($tester)      = Test -> new
	(
	 directory => $directory,
	 dsn       => $data_source,
	 dsn_attr  => {PrintError => 0}, # Stop msg when trying to delete non-existant table.
	 password  => '',
	 type      => $type,
	 username  => '',
	 verbose   => 1,
	);

$tester -> setup_table(128);

my($session) = Data::Session -> new
(
	dbh     => $tester -> dbh,
	type    => $type,
	verbose => 0, # Affects parse_options().
) || die $Data::Session::errstr;

my($sub) = sub
{
	my($id) = @_;
	my($s)  = Data::Session -> new
	(
		dbh     => $tester -> dbh,
		id      => $id,
		type    => $type,
		verbose => 1, # Affects check_expiry() & parse_options().
	) || die $Data::Session::errstr;

	$s -> expire(-1);
	$s -> check_expiry;
};

$session -> traverse($sub);
