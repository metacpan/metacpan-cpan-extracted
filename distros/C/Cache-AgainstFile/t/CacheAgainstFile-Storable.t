#!/usr/local/bin/perl
use strict;
use Test::Assertions qw(test);
use Log::Trace;
use Getopt::Std;
use File::Path;

use vars qw($opt_t $opt_T $opt_d);
getopts('tTd');

plan tests => 39;

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
require Cache::AgainstFile::Storable;
ASSERT(1, "compiled version $Cache::AgainstFile::Storable::VERSION");

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

goto trans if($opt_d);

############################################################################
### Disk caching
############################################################################
my $disk_cache = new Cache::AgainstFile($callback, {Method => 'Storable', 'CacheDir' => $cache_dir});
ASSERT($disk_cache->{method} eq 'Storable', "Storable caching");
test_basics($disk_cache, $filename);
$disk_cache = new Cache::AgainstFile($callback, {Method => 'Storable', 'CacheDir' => $cache_dir."/", 'NoStat' => 1, Locking => 'Flock'});
test_nostat($disk_cache, $filename);
$disk_cache = new Cache::AgainstFile($callback, {Method => 'Storable', 'CacheDir' => $cache_dir, 'MaxItems' => 2, Locking => 'AtomicWrite'});
test_max_items($disk_cache, $dir, 2);

#delete the cache dir so we have to create it
rmtree($cache_dir);
$disk_cache = new Cache::AgainstFile($callback, {Method => 'Cache::AgainstFile::Storable', 'CacheDir' => $cache_dir, 'MaxATime' => (2.5 * SLEEP_INT)}); #fq backend
rmtree($cache_dir); #delete underneath cache
ASSERT(DIED(sub {
	$disk_cache->count()
}) && $@ =~ /unable to open directory/, "failed dir read raises exception");
mkpath($cache_dir); #mend it again
test_old_items($disk_cache, $dir, 5, 3);

# do the same but during a get() request
rmtree($cache_dir);
$disk_cache = new Cache::AgainstFile(sub {}, {Method => 'Storable', 'CacheDir' => $cache_dir, Locking=>'AtomicWrite', MaxATime => SLEEP_INT});
$disk_cache->get($filename);
ASSERT(-e $cache_dir && -d _, "Directory was created on demand");
sleep 2*SLEEP_INT;
$disk_cache->purge;
rmtree($cache_dir);
ASSERT(! -e $cache_dir, "Directory no longer exists");
$disk_cache->get($filename);
# the above get() will die() if the test fails, so we just need to check we've got this far
ASSERT('ok', "get() method successfully recreated directory on demand");

############################################################################
### Error trapping
############################################################################

ASSERT(DIED(sub {
	new Cache::AgainstFile::Storable(sub {}, {})
}) && $@ =~ /You must supply a cache directory/, "no cache dir raises exception");

ASSERT(DIED(sub {
	new Cache::AgainstFile::Storable(sub {}, {CacheDir => $cache_dir, Locking => 'Garbage'})
}) && $@ =~ /Unrecognised locking model/, "invalid locking strategy raises exception");

############################################################################
### Filename translation testing
############################################################################

trans:

$disk_cache = Cache::AgainstFile::Storable->new(sub {}, {'CacheDir' => $cache_dir});
my @trans = (
	['x', "x", "plain file"],
	['x/y', "x%2Fy", "file in subdir"],
	['/x/:y!', "%2Fx%2F%3Ay%21", "file with wierd chars in name"],
	['/h/s/d%x', "%2Fh%2Fs%2Fd%25x", "file with esc char in name"],
	['C:/Temp/baz', "C%3A%2FTemp%2Fbaz", "Win32 drive letter"],
);

foreach my $row (@trans) {
	my ($k, $v, $desc) = @$row;
	my $rv = $disk_cache->_filename2cache($k);
	TRACE("got $rv (expected $v)");
	ASSERT(scalar $rv =~ /\Q$v\E$/i, "$desc - filename2cache");
	$rv = $disk_cache->_cache2filename($rv);
	ASSERT(scalar $rv =~ /\Q$k\E$/i, "$desc - cache2filename");
	TRACE("got $rv (expected $k)");
}


############################################################################
# Clean up
############################################################################
END {
	TRACE("Cleaning up $dir");
	rmtree($dir);
	rmtree($cache_dir);
}

