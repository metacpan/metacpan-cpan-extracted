package DarkPAN::Indexer::Storage;

# The storage contract. This is an INTERFACE role, not a behavior mixin:
# it provides almost nothing and instead `requires` the six methods every
# storage engine must implement. A class becomes a usable backend by:
#
#   package DarkPAN::Indexer::Storage::Foo;
#   use Role::Tiny::With;
#   with 'DarkPAN::Indexer::Storage';   # dies at compile time if a
#                                       # required method is missing
#
# The loader resolves a config `type` to DarkPAN::Indexer::Storage::<type>
# (or a +Fully::Qualified name verbatim), requires it, and asserts
#   $class->DOES('DarkPAN::Indexer::Storage')
# before constructing via new_from_config. So `requires` guarantees the
# methods exist; DOES guarantees the class actually consumed this role.
#
# TWO LAYERS, don't confuse them. These are the generic, backend-specific
# primitives (byte movers + enumeration + lock). The DOMAIN layer
# (Role::Indexer, Role::Utils) speaks intent -- fetch_packages_version_index,
# save_packages_version_index -- and calls DOWN to these. Domain names
# never appear here; a backend does not know what an "index" is, only how
# to move bytes for a key.

use strict;
use warnings;

use Carp qw(croak);
use English qw(-no_match_vars);
use File::Temp qw(tempfile);

use Role::Tiny;

# --- construction -----------------------------------------------------
#
# new($class, $entry)
#   Build an engine from a merged config entry (see the config schema).
#   Each engine reads its own settings from $entry->{storage}; the S3
#   engine additionally honors a legacy $entry->{AWS} block, storage
#   winning on collision. Other engines are greenfield -- storage only.
requires 'new';

# --- enumeration (domain-aware, backend-specific) ---------------------
#
# list_distributions() -> list of keys (relative to the storage root)
#   that are distribution tarballs. This is the ONE seam method that
#   legitimately understands the tree: it decides what counts as a
#   distribution (e.g. the .tar.gz filter) and where to scan. Everything
#   else here is dumb byte movement.
requires 'list_distributions';

# --- object primitives (generic, key-in / bytes-out) ------------------
#
# fetch_object($key) -> raw bytes, or undef if the key is genuinely
#   absent. A real I/O error throws (fail-fast). Keys are always
#   relative to the storage root; the engine resolves them (bucket+key,
#   root+path, etc).
requires 'fetch_object';

# save_object($key, $bytes, %opts) -> writes bytes at $key. %opts may
#   carry content_type. Content is already in final form (the domain
#   layer gzips before calling); this moves bytes only. Throws on failure.
requires 'save_object';

# has_object($key) -> boolean. Existence check (the head-object case).
requires 'has_object';

# --- mutual exclusion -------------------------------------------------
#
# lock($key, %opts) -> a GUARD object on success, false on failure.
#   The guard is true, and releases the lock in DESTROY when it leaves
#   scope (including on die). Callers MUST bind it to a lexical for the
#   whole critical section:
#
#       my $guard = $storage->lock($key, ttl => 300, wait => 60)
#         or croak 'could not acquire lock';
#       ... fetch -> mutate -> save ...
#       # $guard drops here -> release
#
#   Discarding the return releases immediately and defeats the mutex.
#   %opts: ttl (seconds a held lock stays fresh), wait (seconds to block
#   trying to acquire; 0 = don't wait). Mechanism is engine-specific
#   (S3 conditional-PUT vs flock); the contract above is not.
requires 'lock';

# --- read path --------------------------------------------------------
#
# base_url() -> the public base URL from which a read-only consumer (the
#   resolver) reaches this DarkPAN, or undef if it has none (e.g. a
#   purely local store with no web front). The resolver fetches
#   "{base_url}/{index path}". This is derived from config (`url`), not
#   from the storage backend's own endpoint -- an S3 store fronted by
#   CloudFront reads from the CloudFront domain, not the bucket.
requires 'base_url';

########################################################################
sub _slurp {
########################################################################
  my ( $self, $file ) = @_;

  local $RS = undef;

  my $content;

  open my $fh, '<', $file
    or croak "ERROR: could not open $file for reading\n$OS_ERROR";

  binmode $fh;

  $content = <$fh>;
  close $fh;

  return $content;
}

########################################################################
sub publish_index {
########################################################################
  my ( $self, $temp_index, $index ) = @_;

  my $uncompressed_content = $self->_slurp($temp_index);
  my $content              = q{};

  my $is_zipped = $index =~ /[.]gz$/xsm;

  if ($is_zipped) {
    require IO::Compress::Gzip;

    IO::Compress::Gzip::gzip( \$uncompressed_content, \$content )
      or croak "ERROR: could not gzip $temp_index\n";
  }
  else {
    $content = $uncompressed_content;
  }

  $self->save_object( $index, $content, content_type => $is_zipped ? 'application/gzip' : 'application/octet-stream' );

  return;
}

########################################################################
sub retrieve_index {
########################################################################
  my ( $self, $index ) = @_;

  my $is_zipped = $index =~ /[.]gz$/xsm;

  my $compressed_content = $self->fetch_object($index);
  my $content            = q{};

  if ($is_zipped) {
    require IO::Uncompress::Gunzip;

    IO::Uncompress::Gunzip::gunzip( \$compressed_content, \$content )
      or croak "ERROR: could not unzip $index\n";
  }
  else {
    $content = $compressed_content;
  }

  my ( $fh, $temp_index ) = tempfile( DIR => '/tmp', UNLINK => 0 );
  binmode $fh;

  print {$fh} $content;

  close $fh;

  return $temp_index;
}

1;
