#!/usr/bin/env perl

use strict;
use warnings;

use Cache::Memcached;

use Data::Session;

# -------------------

my($memd) = Cache::Memcached -> new({namespace => 'data.session.id', servers => ['127.0.0.1:11211']});
my($test)  = $memd -> set(time => time);
if (! $test || ($test != 1) )
{
	print "memcached is not responding. \n";
	exit;
}
$memd -> delete('time');

my($type) = 'driver:Memcached;id:SHA1;serialize:DataDumper'; # Case-sensitive.

my($id);

{
my($session) = Data::Session -> new
(
	cache => $memd,
	type  => $type,
) || die $Data::Session::errstr;

$id = $session -> id;

$session -> param(a_key => 'a_value');

print "Id: $id. Save a_key: a_value. \n";
}

{
my($session) = Data::Session -> new
(
	cache => $memd,
	id    => $id,
	type  => $type,
) || die $Data::Session::errstr;

print "Id: $id. Recover a_key: ", $session -> param('a_key'), ". \n";

$session -> delete;
}
