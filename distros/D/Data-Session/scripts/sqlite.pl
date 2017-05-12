#!/usr/bin/env perl

use lib 't';
use strict;
use warnings;

use Data::Session;

use File::Spec;
use File::Temp;

use Test;

# -----------------------------------------------

# The EXLOCK is for BSD-based systems.

my($directory)   = File::Temp::newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
my($data_source) = 'dbi:SQLite:dbname=' . File::Spec -> catdir($directory, 'sessions.sqlite');
my($type)        = 'driver:SQLite;id:SHA1;serialize:DataDumper'; # Case-sensitive.
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

my($id);

{
my($session) = Data::Session -> new
(
	data_source => $data_source,
	type        => $type,
) || die $Data::Session::errstr;

$id = $session -> id;

$session -> param(a_key => 'a_value');

print "Id: $id. Save a_key: a_value. \n";
}

{
my($session) = Data::Session -> new
(
	data_source => $data_source,
	id          => $id,
	type        => $type,
) || die $Data::Session::errstr;

print "Id: $id. Recover a_key: ", $session -> param('a_key'), ". \n";

$session -> delete;
}
