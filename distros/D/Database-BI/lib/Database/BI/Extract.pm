package Database::BI::Extract;

use strict;
use warnings;

our $VERSION = '0.016.0';

use Carp		qw(croak carp);
use Digest::MD5		qw(md5_hex);
use File::Path		qw(make_path remove_tree);
use Mojo::File;

# ---------------------------------------------------------------------------
# An extract is a SQLite materialisation of one dataset, stored at:
#   <model_dir>/extracts/<fingerprint>.db
#
# The fingerprint is md5_hex(spec . "\0" . mtime . "\0" . size).
# It is a pure cache: deleting the extracts/ directory at any time leaves
# the application fully functional.  No file under data_dir is created.
#
# The caller (Dashboard._get_or_build_extract) is responsible for deciding
# whether to build a new extract; Extract only stores and retrieves bytes.
# ---------------------------------------------------------------------------

# new( model_dir => $dir ) -> $self
sub new {
	my ($class, %args) = @_;
	croak 'model_dir is required' unless defined $args{model_dir};
	return bless { model_dir => $args{model_dir} }, $class;
}

# _fingerprint( $spec, $mtime, $size ) -> $hex_string
sub _fingerprint {
	my ($spec, $mtime, $size) = @_;
	$mtime //= 0;
	$size  //= 0;
	return md5_hex(join("\0", $spec, $mtime, $size));
}

# _extract_dir( $self ) -> $path_string
sub _extract_dir {
	my $self = shift;
	return Mojo::File->new($self->{model_dir})->child('extracts')->to_string;
}

# path( $spec, $mtime, $size ) -> $path_string
#
# Returns the filesystem path an extract for this fingerprint would occupy.
# Does not test for existence.
sub path {
	my ($self, $spec, $mtime, $size) = @_;
	my $fp = _fingerprint($spec, $mtime, $size);
	return Mojo::File->new($self->_extract_dir)->child("$fp.db")->to_string;
}

# get( $spec, $mtime, $size ) -> $path_string | undef
#
# Returns the path to the cached SQLite file when the fingerprint matches and
# the file exists on disk; returns undef on a cache miss.
sub get {
	my ($self, $spec, $mtime, $size) = @_;
	my $p = $self->path($spec, $mtime, $size);
	return -f $p ? $p : undef;
}

# put( $spec, $mtime, $size, $sqlite_bytes ) -> $path_string
#
# Writes $sqlite_bytes to the cache.  Creates the extracts/ directory if it
# does not exist yet.  Returns the path written to.  Croaks on I/O failure.
sub put {
	my ($self, $spec, $mtime, $size, $bytes) = @_;
	croak 'sqlite_bytes are required' unless defined $bytes && length $bytes;

	my $dir = $self->_extract_dir;
	unless (-d $dir) {
		eval { make_path($dir) };
		croak "Cannot create extract dir '$dir': $@" if $@;
	}

	my $p = $self->path($spec, $mtime, $size);
	eval { Mojo::File->new($p)->spurt($bytes) };
	croak "Cannot write extract '$p': $@" if $@;

	return $p;
}

# evict( $spec ) -> $count_removed
#
# Removes all cached extract files that begin with a fingerprint that could
# belong to $spec.  Because the fingerprint includes mtime+size, a changed
# file naturally produces a miss without eviction; evict() is provided for
# explicit cache clearing.  Returns the number of files removed.
# NOTE: because fingerprints are global md5 hashes we cannot identify which
# belong to a spec without re-computing; this method removes ALL extracts.
# Call it only when clearing the whole extract store is desired.
sub evict {
	my ($self, $spec) = @_;
	my $dir = $self->_extract_dir;
	return 0 unless -d $dir;

	my $count = 0;
	for my $f (glob "$dir/*.db") {
		if (unlink $f) {
			$count++;
		}
	}
	return $count;
}

1;

__END__

=head1 NAME

Database::BI::Extract -- SQLite materialisation cache for Database::BI

=head1 SYNOPSIS

  use Database::BI::Extract;

  my $cache = Database::BI::Extract->new(model_dir => '.bi');

  # Check cache
  my $path = $cache->get($spec, $mtime, $size);
  unless ($path) {
      my $bytes = ...; # build the SQLite file
      $path = $cache->put($spec, $mtime, $size, $bytes);
  }

=head1 DESCRIPTION

Stores SQLite materialisation files (extracts) under C<model_dir/extracts/>.
The cache key is an MD5 of the dataset spec, its source mtime, and its size.
Deleting the extracts directory leaves the application fully functional.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.
Usage is subject to the GPL2 licence terms.

=cut
