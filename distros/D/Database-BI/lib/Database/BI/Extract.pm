package Database::BI::Extract;

use strict;
use warnings;

our $VERSION = '0.018.0';

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
# This is a standalone cache class: the web application does not call it (the
# routes read their sources directly), and the tests cover the class itself.
# A caller decides whether to build a new extract; Extract only stores and
# retrieves bytes.
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

This is a standalone cache class.  The web application does not call it; the
caller decides when to build an extract, and the class only stores and finds
the bytes.

=head1 METHODS

=head2 new

=head3 API SPECIFICATION

=head4 INPUT

	{ model_dir => 'string' }   # required; extracts live in <model_dir>/extracts/

=head4 OUTPUT

A C<Database::BI::Extract> object.  Croaks C<model_dir is required> without
C<model_dir>.  Nothing is created on disc until C<put>.

=head2 path

=head3 API SPECIFICATION

=head4 INPUT

	$spec    # the dataset spec, e.g. 'table:sales'
	$mtime   # source modification time (undef is 0)
	$size    # source size in bytes (undef is 0)

=head4 OUTPUT

	'string'   # <model_dir>/extracts/<md5 of spec, mtime and size>.db

The path is computed, not checked: the file need not exist.

=head2 get

=head3 API SPECIFICATION

=head4 INPUT

The same three arguments as C<path>.

=head4 OUTPUT

	'string' | undef   # the path when that file exists, otherwise undef

A changed mtime or size gives a different path, so a stale extract is a miss.

=head2 put

=head3 API SPECIFICATION

=head4 INPUT

	$spec, $mtime, $size   # as for path
	$bytes                 # required; the SQLite file's contents

=head4 OUTPUT

	'string'   # the path written

Creates C<extracts/> when it is missing.  Croaks C<sqlite_bytes are required>
when C<$bytes> is undefined or empty, and croaks naming the path when the
directory or file cannot be written.

=head2 evict

=head3 API SPECIFICATION

=head4 INPUT

	$spec   # accepted but not used: see below

=head4 OUTPUT

	'integer'   # the number of files removed (0 when there is no extracts/)

A fingerprint cannot be traced back to its spec, so C<evict> removes every
C<.db> file in C<extracts/>, not only C<$spec>'s.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.
Usage is subject to the GPL2 licence terms.

=cut
