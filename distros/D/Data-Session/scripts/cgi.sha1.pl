#!/usr/bin/env perl

use strict;
use warnings;

use CGI;

use Data::Session;

use File::Spec;
use File::Temp;

# -----------------------------------------------

# The EXLOCK is for BSD-based systems.

my($directory) = File::Temp::newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
my($file_name) = 'session.%s.dat';
my($type)      = 'driver:File;id:SHA1;serialize:DataDumper'; # Case-sensitive.

my($id);

{
my($session) = Data::Session -> new
(
	directory => $directory,
	file_name => $file_name,
	type      => $type,
) || die $Data::Session::errstr;

$id = $session -> id;

$session -> param(a_key => 'a_value');

print "Id: $id. Save: a_key => a_value. \n";
}

{
my($q) = CGI -> new;

$q -> param(CGISESSID => $id);

my($session) = Data::Session -> new
(
	directory => $directory,
	file_name => $file_name,
	query     => $q,
	type      => $type,
) || die $Data::Session::errstr;

print "Id: $id. Recover: a_key => ", $session -> param('a_key'), ". \n";

$session -> delete;
}
