#!/usr/bin/env perl

use strict;
use warnings;

use Data::Session;

use File::Spec;
use File::Temp;

# -----------------------------------------------

# The EXLOCK is for BSD-based systems.

my($directory) = File::Temp::newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
my($file_name) = 'autoinc.session.dat';
my($id_file)   = File::Spec -> catfile($directory, $file_name);
my($type)      = 'driver:File;id:AutoIncrement;serialize:DataDumper'; # Case-sensitive.

my($id);

{
my($session) = Data::Session -> new
(
	id_base     => 99,
	id_file     => $id_file,
	id_step     => 2,
	type        => $type,
) || die $Data::Session::errstr;

$id = $session -> id;

$session -> param(a_key => 'a_value');

print "Id: $id. Save: a_key => a_value. \n";
}

{
my($session) = Data::Session -> new
(
	id      => $id,
	id_file => $id_file,
	type    => $type,
) || die $Data::Session::errstr;

print "Id: $id. Recover: a_key => ", $session -> param('a_key'), ". \n";

$session -> delete;
}
