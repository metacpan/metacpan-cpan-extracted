#!/usr/local/bin/perl
use strict;
use Test::Assertions qw(test);
use Log::Trace;
use Getopt::Std;
use File::Path;

use vars qw($opt_t $opt_T $opt_d);
getopts('tTd');

plan tests => 8;
ignore(1..8) unless($^O eq 'MSWin32');

#Move into the t directory
chdir($1) if ($0 =~ /(.*)(\/|\\)(.*)/);
use lib qw(.);

#Compile
unshift @INC, "../lib";
require Cache::AgainstFile;
require Cache::AgainstFile::Storable;

#Log::Trace
import Log::Trace qw(print) if($opt_t);
deep_import Log::Trace qw(print) if($opt_T);

#Test directories
my $cache_dir = './cache';

my $disk_cache = Cache::AgainstFile::Storable->new(sub {}, {'CacheDir' => $cache_dir});

my @trans = (
	['x', qr'.*/x$', "plain file"],
	['x\y', qr'.*/x/y$', "file in subdir - backslash"],
	['x/y', qr'.*/x/y$', "file in subdir - fwd slash"],
	['/x/y', qr'^\w+:/x/y$', "absolute path"],
	["\\\\server\\share", qr'^//server/share$', "UNC path - backslashes"],
	['//server/share', qr'^//server/share$', "UNC path - forward slashes"],
	['C:\Temp\baz', qr'^c:/temp/baz$', "Win32 drive letter - backslashes"],
	['C:/Temp/baz', qr'^c:/temp/baz$', "Win32 drive letter - forward slashes"],
);

foreach my $row (@trans) {
	my ($k, $regex, $desc) = @$row;
	my $rv = $disk_cache->_filename2cache($k);
	$rv = $disk_cache->_cache2filename($rv);
	TRACE("got $rv (expected $k)");
	ASSERT(scalar $rv =~ $regex, $desc);
}


