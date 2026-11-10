package Database::BI::Extract;

use strict;
use warnings;

our $VERSION = '0.022.0';

use Carp		qw(croak carp);
use Digest::MD5		qw(md5_hex);
use Encode		qw(encode_utf8);
use File::Path		qw(make_path remove_tree);
use Mojo::File;
use Readonly;

# ---------------------------------------------------------------------------
# An extract is a SQLite materialisation of one dataset, stored at:
#   <model_dir>/extracts/<fingerprint>.db
# or, when a cache directory is set (see new), at:
#   <cache_dir>/database-bi-extracts/<fingerprint>.db
#
# The fingerprint is md5_hex(spec . "\0" . mtime . "\0" . size).
# It is a pure cache: deleting the extracts/ directory at any time leaves
# the application fully functional.  No file under data_dir is created.
#
# The web application reads an accelerated dataset's extract through get(), and
# script/bi-extract builds one through put() (Dashboard::accelerate).  A caller
# decides whether to build a new extract; Extract only stores and retrieves
# bytes.
# ---------------------------------------------------------------------------

# The folder extracts are kept in under a cache directory that was set, rather
# than in it: evict() removes every .db file it finds, and a CACHEDIR such as
# ~/.cache holds other programs' files.
Readonly my $CACHE_SUBDIR => 'database-bi-extracts';

# new( model_dir => $dir, cache_dir => $dir, config => \%conf, home => $dir, dir => $dir ) -> $self
#
# Database::BI::CacheDir chooses the cache directory (Object::Configure,
# CACHEDIR, CACHE_DIR, cache_dir in database_bi.conf); the extracts go in its
# database-bi-extracts folder.  With none of those set they stay in
# <model_dir>/extracts, where they always were.
sub new {
	my ($class, %args) = @_;

	# dir names the folder outright, choosing nothing.
	return bless { model_dir => $args{model_dir}, dir => $args{dir} }, $class
		if defined($args{dir}) && length($args{dir});

	require Database::BI::CacheDir;
	my $cache_dir = Database::BI::CacheDir::resolve(
		class  => $class,
		params => \%args,
		(exists($args{config}) ? (config => $args{config}, home => $args{home}) : ()),
	);

	my $dir;
	if (defined $cache_dir) {
		$dir = Mojo::File->new($cache_dir)->child($CACHE_SUBDIR)->to_string;
	} else {
		croak 'model_dir is required' unless defined $args{model_dir} && length $args{model_dir};
		$dir = Mojo::File->new($args{model_dir})->child('extracts')->to_string;
	}

	return bless { model_dir => $args{model_dir}, dir => $dir }, $class;
}

# dir( $self ) -> $path_string
#
# The folder the extracts are kept in.  It need not exist yet.
sub dir {
	my $self = shift;
	return $self->{dir};
}

# _fingerprint( $spec, $mtime, $size ) -> $hex_string
sub _fingerprint {
	my ($spec, $mtime, $size) = @_;
	$mtime //= 0;
	$size  //= 0;
	return md5_hex(encode_utf8(join("\0", $spec, $mtime, $size)));
}

# _extract_dir( $self ) -> $path_string
sub _extract_dir {
	my $self = shift;
	return $self->{dir};
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

	# A caller's $@ and $! are its own: the writes below use both on the way.
	local ($@, $!);

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
	# Listed rather than globbed: glob() splits its pattern on spaces and reads
	# brackets as a class, so the name of the directory could defeat it.
	for my $f (grep { /\.db\z/ } @{ Mojo::File->new($dir)->list->map('to_string') }) {
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

Stores SQLite materialisation files (extracts) under C<model_dir/extracts/>,
or under F<database-bi-extracts/> in the cache directory when one is set (see
L</new>).
The cache key is an MD5 of the dataset spec, its source mtime, and its size.
Deleting the extracts directory leaves the application fully functional.

The application reads the extract of an accelerated dataset through C<get>,
and C<script/bi-extract> builds one through C<put>; see
L<Database::BI/Accelerated datasets>.  The caller decides when to build an
extract, and the class only stores and finds the bytes.

=head1 METHODS

=head2 new

=head3 API SPECIFICATION

=head4 INPUT

	{
		model_dir => 'string',   # extracts live in <model_dir>/extracts/ when no cache directory is set
		dir       => 'string',   # optional; the folder itself, used as given: nothing below is read
		cache_dir => 'string',   # optional; read through Object::Configure (below)
		config    => 'hashref',  # optional; the application's config (default: database_bi.conf is read)
		home      => 'string',   # optional; the folder a relative cache_dir in config is under
	}

The cache directory is the first of these that is set (see
L<Database::BI::CacheDir>): C<cache_dir> through L<Object::Configure> (its
config files, then C<Database__BI__Extract__cache_dir>; the C<cache_dir>
argument is what those fall back on), C<$ENV{CACHEDIR}>, C<$ENV{CACHE_DIR}>,
C<cache_dir> in F<database_bi.conf>.  The extracts are then kept in its
F<database-bi-extracts/> folder, never in it directly, because C<evict> removes
every C<.db> file in the folder it uses.

=head4 OUTPUT

A C<Database::BI::Extract> object.  Croaks C<model_dir is required> when
neither C<model_dir> nor a cache directory is set.  Nothing is created on disc
until C<put>.

=head2 dir

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

	'string'   # the folder the extracts are kept in; it need not exist

=head2 path

=head3 API SPECIFICATION

=head4 INPUT

	$spec    # the dataset spec, e.g. 'table:sales'
	$mtime   # source modification time (undef is 0)
	$size    # source size in bytes (undef is 0)

=head4 OUTPUT

	'string'   # <dir>/<md5 of spec, mtime and size>.db

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

Creates C<dir> when it is missing.  Croaks C<sqlite_bytes are required>
when C<$bytes> is undefined or empty, and croaks naming the path when the
directory or file cannot be written.

=head2 evict

=head3 API SPECIFICATION

=head4 INPUT

	$spec   # accepted but not used: see below

=head4 OUTPUT

	'integer'   # the number of files removed (0 when there is no dir)

A fingerprint cannot be traced back to its spec, so C<evict> removes every
C<.db> file in C<dir>, not only C<$spec>'s.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.
Usage is subject to the GPL2 licence terms.

=cut
