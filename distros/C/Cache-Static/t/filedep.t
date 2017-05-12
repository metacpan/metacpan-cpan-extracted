#!/usr/bin/perl -w

#for when we are invoked from "make test"
use lib "t";

use strict;
use TEST;

sub mktemp {
	my $base = "$Cache::Static::ROOT/Cache-Static-testfile-";
	return $base.(int rand 99999);
}

sub touch {
	my $file = shift;
	open(FH, ">$file") || die "can't write to $Cache::Static::ROOT, please set to a writable directory in t/TEST.pm";
	close(FH);
}

print "1..9\n";

my $key = Cache::Static::make_key("filedep test key");
ok ( "make key", '1/Y/M/Y2e7N_A9NRKqmbbv1vA' eq $key );

my $tmpfile = mktemp();

ok ( "get if same:file not found",
	!Cache::Static::get_if_same($key, [ "file|$tmpfile" ] ) );

touch($tmpfile);
ok ( "get if same:file found, but no cache yet",
	!Cache::Static::get_if_same($key, [ "file|$tmpfile" ] ) );

eval { Cache::Static::set($key, "value", [ "file|$tmpfile" ] ); };
ok ( "set1", !$@); 

ok ( "get if same after set",
	Cache::Static::get_if_same($key, [ "file|$tmpfile" ] ) );

sleep(1);
touch($tmpfile);
ok ( "get if same after set and dep touch",
	!Cache::Static::get_if_same($key, [ "file|$tmpfile" ] ) );

eval { Cache::Static::set($key, "value", [ "file|$tmpfile" ] ); };
ok ( "set2", !$@); 

ok ( "get if same after set, dep touch, and re-set",
	Cache::Static::get_if_same($key, [ "file|$tmpfile" ] ) );

unlink($tmpfile);
ok ( "get if same after unlink",
	!Cache::Static::get_if_same($key, [ "file|$tmpfile" ] ) );

exit 0;
