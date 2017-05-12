#!/usr/bin/perl -w

#for when we are invoked from "make test"
use lib "t";

use strict;
use TEST;

print "1..4\n";

#test namespace-specific configs without init() calls

#create all nec. directories
Cache::Static::_mkdir_p($Cache::Static::ROOT."/a");
Cache::Static::_mkdir_p($Cache::Static::ROOT."/b");

#write the config files out
open(F, ">".$Cache::Static::ROOT."/a/config") || die "can't open a/config";
print F "dep_file_not_found_returns 0" || die "can't print a/config";
close(F) || die "can't close a/config";
open(F, ">".$Cache::Static::ROOT."/b/config") || die "can't open b/config";
print F "dep_file_not_found_returns 1" || die "can't print b/config";
close(F) || die "can't close b/config";

#set the key in both namespaces...
my $key = Cache::Static::make_key('abc', {});
my $set_ret_a = Cache::Static::set($key, "result!",
	[ "file|/path/to/nowhere" ], namespace => "a");
my $set_ret_b = Cache::Static::set($key, "result!",
	[ "file|/path/to/nowhere" ], namespace => "b");

#now try to get it out with a non-existent file path...
my $gis_ret_a = Cache::Static::get_if_same($key, [ "file|/path/to/nowhere" ],
    namespace => "a");
my $gis_ret_b = Cache::Static::get_if_same($key, [ "file|/path/to/nowhere" ],
    namespace => "b");

ok("set_ret_a", $set_ret_a);
ok("set_ret_b", $set_ret_b);
ok("dep_file_not_found_returns 1 override (b)", ($gis_ret_b eq 'result!'));
ok("dep_file_not_found_returns 0 override (a)", (!defined($gis_ret_a)));

