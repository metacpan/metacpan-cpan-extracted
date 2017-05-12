package CIPP::Compile::Cache;

use strict;
use vars qw ( $VERSION );

use Carp;
use File::Basename;
use File::Path;

$VERSION = "0.01";

sub get_cache_status {
	my $type = shift;
	my %par = @_;
	my ($dep_file, $if_file) = @par{'dep_file','if_file'};

	my $DEBUG = 0;

	my $dirty      = 'dirty';
	my $cached_err = 'cached err';
	my $clean      = 'clean';

	$DEBUG && print STDERR "\ndep_file=$dep_file ",(-f$dep_file?"exist":"missing"),"\n";
	$DEBUG && print STDERR "if_file=$if_file ",(-f$if_file?"exist":"missing"),"\n";

	if ( not -f $dep_file or ($if_file and not -f $if_file) ) {
		$DEBUG && print STDERR "no dep_file or not if_file\n";
		return $dirty;
	}

	$DEBUG && print STDERR "dep_file exists\n";

	open (IN, $dep_file) or confess "can't read $dep_file";
	my $line = <IN>;
	chomp $line;

	my ($src_file, $cache_file, $err_file);
	($src_file, $cache_file, $err_file) = split(/\t/, $line);

	my $src_file_mtime = (stat($src_file))[9];

	# check for cached error

	$DEBUG && print STDERR "err_file=$err_file\n";

	my $has_cached_err = 0;

	my $err_file_mtime;
	if ( -f $err_file ) {
		$DEBUG && print STDERR "err-file $err_file OLDER $src_file : ";
		$err_file_mtime = (stat($err_file))[9];
		if ( $err_file_mtime < $src_file_mtime ) {
			# cache is dirty, if err_file is older than src_file
			close IN;
			$DEBUG && print STDERR "YES\n";
			$DEBUG && print STDERR "Status: $dirty\n";
			return $dirty;
		} else {
			# ok has cached err. beyond we check if any
			# includes interface file is newer than our cached
			# error. in this case the cache is dirty, because
			# the cached error may consist of a wrong interface
			# which was then corrected due to the interface
			# change of that include.
			$DEBUG && print STDERR "CACHED ERR\n";
			$has_cached_err = 1;
		}
	} else {
		$DEBUG && print STDERR "no err file\n";
	}

	$DEBUG && print STDERR "cache_file=$cache_file ",(-f$cache_file?"exist":"missing"),"\n";

	if ( not -f $cache_file and not $has_cached_err ) {
		$DEBUG && print STDERR "no cache file present and no cached err\n";
		$DEBUG && print STDERR "Status: $dirty\n";
		return $dirty;
	}

	$DEBUG && print STDERR "$cache_file OLDER $src_file : ";

	my $cache_file_mtime = (stat($cache_file))[9];

	if ( -f $cache_file and $cache_file_mtime < $src_file_mtime ) {
		# cache is dirty, if cache_file is older than src_file
		close IN;
		$DEBUG && print STDERR "YES\n";
		$DEBUG && print STDERR "Status: $dirty\n";
		return $dirty;
	}

	$DEBUG && print STDERR "NO\n";

	# now check include dependencies
	my $status = $clean;
	while (<IN>) {
		chomp;
		($src_file, $cache_file, $if_file) = split (/\t/, $_);

		if ( not -f $cache_file ) {
			$DEBUG && print STDERR "cache_file doesn't exist\n";
			$status = $dirty;
			last;
		}

		if ( not -f $if_file ) {
			$DEBUG && print STDERR "if_file doesn't exist\n";
			$status = $dirty;
			last;
		}

#		$DEBUG && print STDERR "consistency check: $src_file OLDER $if_file : ";
#		
#		if ( (stat($src_file))[9] < (stat($if_file))[9] ) {
#			$DEBUG && print STDERR "YES!!!\n";
#			$DEBUG && print STDERR "removing $if_file, must be regenerated\n";
#			unlink $if_file;
#			$status = $dirty;
#			last;
#		}

		$DEBUG && print STDERR "$cache_file OLDER $src_file : ";

		if ( (stat($cache_file))[9] < (stat($src_file))[9] ) {
			# cache is dirty if one cache_file is older
			# than corresponding src_file
			$status = $dirty;
			$DEBUG && print STDERR "YES\n";
			last;
		}
		$DEBUG && print STDERR "NO\n";
		
		if ( $has_cached_err ) {
			$DEBUG && print STDERR "$err_file OLDER $if_file (incompat. interface?) : ";

			if ( $err_file_mtime < (stat($if_file))[9] ) {
				# cache is dirty if the cached error is older than
				# the if_file (which indicates incompatible
				# interface change)
				$DEBUG && print STDERR "YES\n";
				$status = $dirty;
				last;
			}
			
			$DEBUG && print STDERR "NO\n";
		}

		$DEBUG && print STDERR "$cache_file OLDER $if_file : ";

		if ( $cache_file_mtime < (stat($if_file))[9] ) {
			# cache is dirty if the cache_file_mtime of
			# our object is older than one if_file
			$DEBUG && print STDERR "YES\n";
			$status = $dirty if not $has_cached_err;
			last;
		}

		$DEBUG && print STDERR "NO\n";

	}
	close IN;
	
	$DEBUG && print STDERR "has cached err: $has_cached_err (status=$status)\n";
	
	$status = $cached_err if $has_cached_err and $status eq $clean;

	$DEBUG && print STDERR "Status: $status\n";
	
	return $status;
}

sub write_dep_file {
	my $type = shift;
	
	my %par = @_;

	my  ($dep_file, $src_file, $cache_file, $err_file, $http_file, $entries_href) =
	@par{'dep_file','src_file','cache_file','err_file','http_file','entries_href'};
	
	croak "dep_file, src_file, cache_file, err_file and entries_href must be set"
		unless $dep_file and $src_file and $err_file and
		       $cache_file and $entries_href;

	# --------------------------------------------------------------
	# Format of the dep_file:
	# Line:		Fields:
	# --------------------------------------------------------------
	#  1		src_file     \t cache_file     \t err_file       \t http_file 
	#  2..n		inc_src_file \t inc_cache_file \t inc_iface_file \t err_file  \t http_file
	# --------------------------------------------------------------
	
	my $dir = dirname $dep_file;
	mkpath ($dir, 0, 0770) if not -d $dir;
	open (OUT, "> $dep_file") or confess "can't write $dep_file";
	
	print OUT "$src_file\t$cache_file\t$err_file\t$http_file\n";
	
	foreach my $entry ( values %{$entries_href} ) {
		print OUT $entry,"\n";
	}
	close OUT;

	1;
}

sub load_dep_file_into_entries_hash {
	my $type = shift;
	my %par = @_;

	my $dep_file     = $par{dep_file};
	my $entries_href = $par{entries_href};

	return if not -f $dep_file;

	open (IN, $dep_file) or confess "can't read $dep_file";

	# skip first line. we only need to copy the include entries
	my $line = <IN>;
	chomp $line;

	my $src_file;
	while (<IN>) {
		chomp;
		($src_file) = split (/\t/, $_, 2);
		$entries_href->{$src_file} = $_;
	}
	close IN;
	
	return;
}

sub get_custom_http_header_files {
	my $self = shift;
	my %par = @_;
	my ($dep_file) = @par{'dep_file'};
	
	open (IN, $dep_file) or confess "can't read $dep_file";
	
	my @http_files;
	my $http_file;

	while (<IN>) {
		chomp;
		$http_file = substr($_, rindex($_, "\t")+1);
		if ( -f $http_file ) {
			push @http_files, $http_file if -f $http_file;
		}
	}
	close IN;
	
	return \@http_files;
}

1;
