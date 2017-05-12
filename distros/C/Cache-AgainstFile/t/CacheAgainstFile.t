#!/usr/local/bin/perl
use strict;
use Test::Assertions qw(test);
use Log::Trace;
use Getopt::Std;
use File::Path;

use vars qw($opt_t $opt_T);
getopts('tT');

plan tests;

#Move into the t directory
chdir($1) if ($0 =~ /(.*)(\/|\\)(.*)/);
use lib qw(.);

#Load the library of tests
use constant SLEEP_INT => 2;
use vars qw($callcount $callback);
require "CacheAgainstFile.lib";

#Compile
unshift @INC, "../lib";
require Cache::AgainstFile;
ASSERT($INC{"Cache/AgainstFile.pm"}, "compiled version $Cache::AgainstFile::VERSION");

#Log::Trace
import Log::Trace qw(print) if($opt_t);
deep_import Log::Trace qw(print) if($opt_T);

#Test directories
my $dir = "data";
my $filename = "$dir/foo.dat";

#Set up test env
mkpath($dir);
touch($filename);

############################################################################
# Error checks
############################################################################

#Invalid coderef
ASSERT(DIED(sub {
	new Cache::AgainstFile({}, {Method => 'Null'})
}) && $@ =~ /not a code reference/, "Check for coderef");

#Invalid hashref
ASSERT(DIED(sub {
	new Cache::AgainstFile($callback, [])
}) && $@ =~ /not a hash reference/, "Check for hashref");

#No backend
ASSERT(DIED(sub {
	new Cache::AgainstFile($callback, {})
}) && $@ =~ /No cache 'Method' option/, "Check for backend");

#Invalid backend
ASSERT(DIED(sub {
	new Cache::AgainstFile($callback, {Method => ';'})
}) && $@ =~ /Package name 'Cache::AgainstFile::;' doesn't look valid/, "Check for valid backend");

#Non-existant backend
ASSERT(DIED(sub {
	new Cache::AgainstFile($callback, {Method => 'DoesNotExist'})
}) && $@ =~ /Unable to load Cache::AgainstFile::DoesNotExist/, "non-existant backend");

############################################################################
# Null cache
############################################################################
my $null_cache = new Cache::AgainstFile($callback, {Method => 'Cache::AgainstFile::Null'});
ASSERT(ref $null_cache eq 'Cache::AgainstFile', 'Object is of correct class');
ASSERT($null_cache->get($filename) eq "filename:$filename", "Null cache");
ASSERT($null_cache->size() == 0, "Null cache - size");
ASSERT($null_cache->count() == 0, "Null cache - count");
$null_cache->purge();
ASSERT(1, "Null cache - purge");
$null_cache->clear();
ASSERT(1, "Null cache - clear");


############################################################################
# Clean up
############################################################################
END {
	TRACE("Cleaning up $dir");
	rmtree($dir);
}

