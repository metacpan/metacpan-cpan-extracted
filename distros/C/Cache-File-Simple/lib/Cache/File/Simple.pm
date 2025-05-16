#!/usr/bin/env perl

package Cache::File::Simple;

use Exporter 'import';
our @EXPORT = qw(cache);

use strict;
use warnings;
use v5.16;

use JSON::PP;
use Tie::File;
use File::Path;
use Digest::SHA qw(sha256_hex);
use File::Basename;

our $CACHE_ROOT     = "/tmp/cacheroot/";
our $DEFAULT_EXPIRE = 3600;

# https://pause.perl.org/pause/query?ACTION=pause_operating_model#3_5_factors_considering_in_the_indexing_phase
our $VERSION = '0.1';

###############################################################################
###############################################################################

# Cache get: cache($key);
# Cache set: cache($key, $val, $expires = 3600);
sub cache {
	my ($key, $val, $expire, $ret, @data) = @_;

	my $hash = sha256_hex($key || "");
	my $dir  = "$CACHE_ROOT/perl-cache/" . substr($hash, 0, 3);
	my $file = "$dir/$hash.json";
	mkpath($dir);

	tie @data, 'Tie::File', $file or die("Unable to write $file"); # to r/w file

	if (@_ > 1) { # Set
		my $expires = int($expire || 0) || time() + $DEFAULT_EXPIRE;
		$data[0]    = encode_json({ expires => $expires, data => $val, key => $key });
		$ret        = 1;
	} elsif ($key && -r $file) { # Get
		eval { $ret = decode_json($data[0]); };
		if ($ret->{expires} && $ret->{expires} > time()) {
			$ret = $ret->{data};
		} else {
			unlink($file);
			$ret = undef;
		}
	}

	return $ret;
}

# $num = cache_clean()
sub cache_clean {
	my ($verbose) = @_;
	my $ret = 0;

	# https://www.perturb.org/display/1306_Perl_Nested_subroutines.html
	local *dir_is_empty = sub {
		opendir(my $dh, $_[0]) or return undef;
		return scalar(grep { $_ ne "." && $_ ne ".." } readdir($dh)) == 0;
	};

	foreach my $file (glob("$CACHE_ROOT/*/*.json")) {
		tie my @data, 'Tie::File', $file or die("Unable to write $file");
		my $x = decode_json($data[0] // {});

		if ($x->{expires} < time()) { # File is expired
			if ($verbose) { print "$file is expired\n"; }
			$ret += int(unlink($file));
		}
	}

	foreach my $dir (glob("$CACHE_ROOT/*")) { # Directory is empty
		if (-d $dir && dir_is_empty($dir)) {
			if ($verbose) { print "$dir is empty\n"; }
			$ret += int(rmdir($dir));
		}
	}

	return int($ret);
}

=pod

=head1 NAME

Cache::File::Simple - Dead simple file based caching meachanism

=head1 SYNOPSIS

	use Cache::File::Simple;

	my $ckey = "cust:1234";

	# Get data from the cache
	my $data = cache($ckey);

	# Store a scalar
	cache($ckey, "Jason Doolis");
	cache($ckey, "Jason Doolis", time() + 7200);

	# Store an arrayref
	cache($ckey, [1, 2, 3]);

	# Store a hashref
	cache($ckey, {'one' => 1, 'two' => 2});

	# Delete an item from the cache
	cache($ckey, undef);

=head1 DESCRIPTION

C<Cache::File::Simple> exports a single C<cache()> function automatically.

Store Perl data structures in an on-disk file cache. Cache entries can be given
an expiration time to allow for easy clean up.

=head1 METHODS

=over 4

=item B<cache($key)>

Get cache data for C<$key> from the cache

=item B<cache($key, $obj)>

Store data in the cache for C<$key>. C<$obj> can be a scalar, listref, or hashref.

=item B<cache($key, $obj, $expires)>

Store data in the cache for C<$key> with an expiration time. C<$expires> is a
unixtime after which the cache entry will be removed.

=item B<cache($key, undef)>

Delete an entry from the cache.

=item B<Cache::File::Simple::cache_clean()>

Manually remove expired entries from the cache. Returns the number of items
expired from the cache;

=item B<$Cache::File::Simple::CACHE_ROOT>

Change where the cache files are stored. Default C</tmp/cacheroot>

=item B<$Cache::File::Simple::DEFAULT_EXPIRES>

Change the default time entries are cached for. Default 3600 seconds

=back

=cut

1;

# vim: tabstop=4 shiftwidth=4 autoindent softtabstop=4
