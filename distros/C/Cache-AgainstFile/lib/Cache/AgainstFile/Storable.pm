###############################################################################
# Purpose : Cache data structures against a file (serialised in files using Storable)
# Author  : John Alden
# Created : 22 Apr 2005 (based on IFL::FileCache)
# CVS     : $Id: Storable.pm,v 1.22 2006/05/09 09:02:32 mattheww Exp $
###############################################################################

package Cache::AgainstFile::Storable;

use strict;
use Carp;
use Cache::AgainstFile::Base;
use Storable qw(store retrieve retrieve_fd lock_store lock_retrieve);
use File::Spec::Functions qw(canonpath catfile rel2abs);
use FileHandle;

use constant IS_WINDOWS => ($^O eq 'MSWin32' ? 1 : 0);
if (IS_WINDOWS) { require Win32 }

use constant HAVE_FILE_POLICY => eval {
	require File::Policy; 
	import File::Policy qw(check_safe);
	1;
};

use vars qw($VERSION @ISA);
$VERSION = sprintf"%d.%03d", q$Revision: 1.22 $ =~ /: (\d+)\.(\d+)/;
@ISA = qw(Cache::AgainstFile::Base);

#
# Public interface
#

sub new {
	my $class = shift;
	my ($loader, $options) = @_;	
	my $self = $class->SUPER::new(@_);

	my $dir = $self->{options}->{CacheDir} || croak("You must supply a cache directory for caching with Storable");
	check_safe($dir,"w") if(HAVE_FILE_POLICY);
	_create_dir_if_required($dir);
	
	#Select locking implementation
	my $locking = $options->{Locking} || 'AtomicWrite';
	if($locking eq 'Flock') {
		$self->{write} = \&_write_locked;
		$self->{read} = \&_read_locked;
	} elsif ($locking eq 'AtomicWrite') {
		$self->{write} = \&_write_atomic;
		$self->{read} = \&_read;
	} else {
		croak("Unrecognised locking model '$locking'");	
	}

	return $self;
}

sub get
{
	my ($self, $filename, @opts) = @_;

	check_safe($filename,"r") if(HAVE_FILE_POLICY);
	
	my $cache_dir = $self->{options}{CacheDir};
	my $cache_filename = catfile($cache_dir, $self->_filename2cache($filename));
	TRACE("cache get - cache filename is '$cache_filename'");
	my $stale = 0;

	# In some (as yet undetermined) circumstances the cachefile directory
	# can disappear, which causes application errors
	_create_dir_if_required($cache_dir);

	# If cachefile doesn't exist, it won't open, implying staleness.
	my $cache_fh = new FileHandle;
	check_safe($cache_filename,"r") if(HAVE_FILE_POLICY);
	unless ($cache_fh->open($cache_filename)) {
		undef $cache_fh;
		$stale = 1;
	}	

	# Compare file mtimes to check staleness		
	my $file_mtime;
	unless ($self->{options}->{NoStat} && !$stale) {
		$file_mtime = (stat($filename))[9];
		my $cache_mtime = ($cache_fh->stat)[9] if $cache_fh;
		$stale = (!defined $file_mtime) || (!defined $cache_mtime) || ($file_mtime != $cache_mtime);
	}
	TRACE("Cache " . ($stale?"is":"is not") . " stale");

	#Read from cache
	my $data;
	if (!$stale) {
		$data = eval { $self->{read}->($cache_filename, $cache_fh) };
		if ($@) {
			warn "Storable couldn't retrieve $cache_filename: $@";
			$stale = 1;
		}
	}
	$cache_fh->close if $cache_fh;
	
	#Write to cache
	if ($stale) {
		TRACE("writing cache");
		$data = $self->{loader}->($filename, @opts);
		$file_mtime = (stat($filename))[9] unless(defined $file_mtime); #Need mtime now
		$self->{write}->($cache_filename, $data, $file_mtime);
	}
	return $data;
}


sub count {
	my ($self) = shift;
	my $files_in_cache = $self->_cache_files;
	return scalar @$files_in_cache;
}

sub size {
	my ($self) = shift;
	my $cache_dir = $self->{options}{CacheDir};
	my $files_in_cache = $self->_cache_files;
	my $sum = 0;
	foreach(@$files_in_cache) {$sum += -s catfile($cache_dir, $_)}
	return $sum;
}

#
# Protected methods referenced from Base class
# 

sub _remove {
	my($self, $keys) = @_;
	my $cache_dir = $self->{options}{CacheDir};
	foreach(@$keys)
	{
		my $filename = $self->_filename2cache($_);
		TRACE("Deleting cache for $_ ($filename)");
		unlink catfile($cache_dir, $filename);
	}
}

sub _accessed {
	my($self) = @_;
	my $cache_dir = $self->{options}{CacheDir};
	my $files_in_cache = $self->_cache_files;
	my %accessed = map
	{
		my $cache_file = catfile($cache_dir, $_);
		$self->_cache2filename($_) => (stat($cache_file))[8]
	}
	@$files_in_cache;
	return \%accessed;
}

sub _stale {
	my($self) = @_;
	my $cache_dir = $self->{options}{CacheDir};
	my $files_in_cache = $self->_cache_files;
	my @out =
	map
	{
		$self->_cache2filename($_)
	}
	grep
	{
		my $cache_file = catfile($cache_dir, $_);
		my $src_mt   = (stat ($self->_cache2filename($_)))[9];
		my $cache_mt = (stat ($cache_file))[9];
		(!defined $src_mt) || (!defined $cache_mt) || ($src_mt != $cache_mt)
	} @$files_in_cache;
	@out;
}

#
# Private methods
#

sub _cache_files {
	my($self) = @_;
	my $cache_dir = $self->{options}{CacheDir};
	local *FH;
	check_safe($cache_dir,"r") if(HAVE_FILE_POLICY);
	opendir (FH, $cache_dir) or die("unable to open directory $cache_dir - $!");
	my @files = grep {$_ !~ /^\./} readdir(FH);
	closedir FH;
	DUMP("cache files", \@files);
	return \@files;
}

#
# Subroutines
#

sub _read_locked {
	my($cache_filename, $fh) = @_;
	# we don't want the filehandle. Suppose it might need to be closed
	# under Win32? Close it anyway
	$fh->close if $fh;
	check_safe($cache_filename,"r") if(HAVE_FILE_POLICY);
	my $ref_data = lock_retrieve($cache_filename);
	TRACE("Fetched from cache file: $cache_filename");
	return $$ref_data;	
}

sub _write_locked {
	my ($cache_filename, $data, $mtime) = @_;
	check_safe($cache_filename,"w") if(HAVE_FILE_POLICY);
	lock_store(\$data, $cache_filename);
	TRACE("wrote cache file: $cache_filename");
	_backtouch($cache_filename, $mtime);
}

sub _write_atomic {
	my ($cache_filename, $data, $mtime) = @_;
	check_safe($cache_filename,"w") if(HAVE_FILE_POLICY);
	my $temp_filename = $cache_filename . ".tmp$$";
	store(\$data, $temp_filename);
	TRACE("wrote temp file: $temp_filename");
	(_backtouch($temp_filename, $mtime)) or die "couldn't set utime on $temp_filename: $!";
	rename($temp_filename, $cache_filename) or die("Unable to rename temporary file '$temp_filename' to cache file '$cache_filename'");
	TRACE("moved to cache file: $cache_filename");
}

sub _backtouch {
	my ($file, $utime) = @_;
	(defined $utime) or confess "need utime";
	# Might not work in race condition? Exception NOT thrown, returns false on failure.
	check_safe($file,"w") if(HAVE_FILE_POLICY);
	return utime (time(), $utime, $file);
}

sub _read {
	my($cache_filename, $fh) = @_;
	my $ref_data;
	check_safe($cache_filename,"r") if(HAVE_FILE_POLICY);
	if (!$fh) {
		TRACE("Reading $cache_filename...");
		$ref_data = retrieve($cache_filename);
	} else {
		TRACE("Reading $cache_filename (from filehandle)...");
		$ref_data = retrieve_fd($$fh);
	}
	return $$ref_data;
}


sub _create_dir_if_required {
	my ($dir) = @_;
	if(! -d $dir) {
		eval {
			require File::Path;
			File::Path::mkpath($dir);	
		};
		croak "Unable to create directory $dir: $@" if $@;
	}
}


# escape and normalise filename
sub _filename2cache {
	my ($self, $filename) = @_;
	TRACE({Level => 2}, "filename = $filename");
	
	#Remove redundant slashes
	$filename = canonpath($filename);
	TRACE({Level => 2}, " - canonpath => $filename");

	#Make absolute
	my $cache_file = rel2abs($filename);  
	TRACE({Level => 2}, " - rel2abs => $cache_file");

	if (IS_WINDOWS) {
		# resolve C:/LONGNA~1 to C:/LongName 
		$cache_file = Win32::GetFullPathName($cache_file);  
		TRACE({Level => 2}, " - fullpathname => $cache_file");
		# normalise path separator
		$cache_file =~ tr:\\:/:;
		TRACE({Level => 2}, " - normalise slashes => $cache_file");
	}

	# escape control chars, special characters, etc e.g. '/' -> '%2F'
	$cache_file =~ s|([^\w\.\-])| sprintf("%%%02X", ord($1)) |eg;

	# normalise case on case-insensitive filesystems
	$cache_file = lc $cache_file if File::Spec->case_tolerant;

	TRACE({Level => 2}," => cache filename = $cache_file");
	TRACE("filename2cache $filename -> $cache_file");
	return $cache_file;
}

# unescape filename
sub _cache2filename {
	my $self = shift;
	my $cache_file = shift;
	(my $filename = $cache_file) =~ s|%([0-9A-Fa-f]{2})| chr(hex($1)) |eg;
	TRACE("cache2filename $cache_file -> $filename");
	return $filename;
}

#
# Log::Trace stubs
#

sub TRACE {}
sub DUMP {}

1;

=head1 NAME

Cache::AgainstFile::Storable - cache data structures parsed from files in Storable files

=head1 SYNOPSIS

	use Cache::AgainstFile;
	my $cache = new Cache::AgainstFile(
		\&loader, 
		{
			Method => 'Storable',
			CacheDir => '/var/tmp/cache/myapp',
			# ...
		}
	);

	$data = $cache->get($filename);

=head1 DESCRIPTION

Data structures parsed from files are cached in "shadow" storable files.
If parsing is significantly more expensive than file I/O (e.g. with XML files),
then this will offer some benefit.

This backend is suitable for non-persistent environments (e.g. CGI scripts)
where you want the cache to outlive the process.  For persistent environments,
the Memory backend may be more suitable as it saves on file I/O.

count() and size() are relatively expensive operations involving scanning the cache directory.

=head1 OPTIONS

=over 4

=item CacheDir

Directory in which to store cache files.  This is mandatory.

=item MaxATime

Purge items older than this.
Value is in seconds (default=undefined=infinity)

=item MaxItems

Purge oldest items from the cache to reduce the number of items in the cache to be at most this number.
Value should be an integer (default=undefined=infinity)

=item NoStat

Don't stat files to validate the cache - items are served from the cache until they are purged.
Valid values are 0|1 (default=0, i.e. files are statted)

=item Locking

Valid values are Flock and AtomicWrite (default is AtomicWrite).
If neither of these are to your taste, consider using Cache::AgainstFile::CacheModule with another caching module.
Some other file caching modules on CPAN are:

=over 4

=item Cache::FileCache

This uses atomic writes.

=item Cache::File

This uses File::NFSLock for locking (no locking is also an option)

=back

=back

=head1 VERSION

$Revision: 1.22 $ on $Date: 2006/05/09 09:02:32 $ by $Author: mattheww $

=head1 AUTHOR

John Alden & Piers Kent <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut
