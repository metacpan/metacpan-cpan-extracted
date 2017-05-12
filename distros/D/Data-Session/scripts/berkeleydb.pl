#!/usr/bin/env perl

use strict;
use warnings;

use BerkeleyDB;

use Data::Session;

use File::Spec;
use File::Temp;

# -------------------

# The EXLOCK is for BSD-based systems.

my($file_name) = File::Temp -> new(EXLOCK => 0, SUFFIX => '.bdb');
my($env)       = BerkeleyDB::Env -> new
(
	Home => File::Spec -> tmpdir,
	Flags => DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL,
);
if (! $env)
{
	print "BerkeleyDB is not responding. \n";
	exit;
}
my($bdb) = BerkeleyDB::Hash -> new(Env => $env, Filename => $file_name, Flags => DB_CREATE);
if (! $bdb)
{
	print "BerkeleyDB is not responding. \n";
	exit;
}
my($type) = 'driver:BerkeleyDB;id:SHA1;serialize:DataDumper'; # Case-sensitive.

my($id);

{
my($session) = Data::Session -> new
(
	cache => $bdb,
	type  => $type,
) || die $Data::Session::errstr;

$id = $session -> id;

$session -> param(a_key => 'a_value');

print "Id: $id. Save a_key: a_value. \n";
}

{
my($session) = Data::Session -> new
(
	cache => $bdb,
	id    => $id,
	type  => $type,
) || die $Data::Session::errstr;

print "Id: $id. Recover a_key: ", $session -> param('a_key'), ". \n";

$session -> delete;
}
