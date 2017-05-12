#!/usr/local/bin/perl
use strict;
use Test::Assertions qw(test);
use Log::Trace;
use Getopt::Std;
use File::Path;

use vars qw($opt_t $opt_T);
getopts('tT');

#Do we have the tools to compute in-memory sizes?
eval {require Devel::Size};
my $size_not_available = (defined $@);

plan tests => 23;

#Move into the t directory
chdir($1) if ($0 =~ /(.*)(\/|\\)(.*)/);
use lib qw(.);

#Load the library of tests
use constant SLEEP_INT => 2.0;
use vars qw($callcount $callback);
require "CacheAgainstFile.lib";

#Compile
unshift @INC, "../lib";
require Cache::AgainstFile;
require Cache::AgainstFile::Memory;
ASSERT($INC{"Cache/AgainstFile/Memory.pm"}, "compiled version $Cache::AgainstFile::Memory::VERSION");

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
# Memory caching
############################################################################
my $mem_cache = new Cache::AgainstFile($callback, {Method => 'Memory'});
ASSERT($mem_cache->{method} eq 'Memory', "Memory backend");
test_basics($mem_cache, $filename, undef, $size_not_available); 
$mem_cache = new Cache::AgainstFile($callback, {Method => 'Memory', 'NoStat' => 1}); 
test_nostat($mem_cache, $filename);
$mem_cache = new Cache::AgainstFile($callback, {Method => 'Memory', 'MaxItems' => 3});
test_max_items($mem_cache, $dir, 3);
$mem_cache = new Cache::AgainstFile($callback, {Method => 'Cache::AgainstFile::Memory', 'MaxATime' => (2.5 * SLEEP_INT)}); #fq backend
test_old_items($mem_cache, $dir, 5, 3);

############################################################################
# Clean up
############################################################################
END {
	TRACE("Cleaning up $dir");
	rmtree($dir);
}

