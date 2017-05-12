#!/usr/local/bin/perl
use strict;
use Test::Assertions qw(test);
use Log::Trace;
use Getopt::Std;
use File::Path;
use constant SLEEP_INT => 2;

use vars qw($opt_t $opt_T);
getopts('tT');

#Look for any installed Cache or Cache::Cache memory caching module
my @cache_modules;
foreach my $module qw(Cache::Memory Cache::MemoryCache){
	eval "require $module";
	push @cache_modules, $module unless($@);
}

plan tests => 2 + 11*scalar @cache_modules;

#Move into the t directory
chdir($1) if ($0 =~ /(.*)(\/|\\)(.*)/);
use lib qw(.);

#Load the library of tests
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
my $cache_dir = './cache';
my $filename = "$dir/foo.dat";

#Set up test env
mkpath($dir);
touch($filename);

############################################################################
# Run tests on installed memory caches
############################################################################
foreach my $cache_module(@cache_modules) {
	my $id = "CacheModule=$cache_module";
	my $cache = new Cache::AgainstFile($callback, {Method => 'CacheModule', CacheModule => $cache_module});
	test_basics($cache, $filename, $id);	
}

#Non-existant cache module raises exception
ASSERT(DIED(sub {
	new Cache::AgainstFile($callback, {Method => 'CacheModule', CacheModule => 'DoesNotExist'})
}) && $@ =~ /Unable to load DoesNotExist/, "non-existant cache module");

############################################################################
# Clean up
############################################################################
END {
	TRACE("Cleaning up $dir and $cache_dir");
	rmtree($dir);
	rmtree($cache_dir);
}

