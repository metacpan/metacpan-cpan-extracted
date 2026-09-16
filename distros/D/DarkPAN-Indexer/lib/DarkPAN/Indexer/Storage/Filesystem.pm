package DarkPAN::Indexer::Storage::Filesystem;

# Filesystem storage engine for DarkPAN::Indexer.
#
# Implements the DarkPAN::Indexer::Storage contract against a local
# directory tree. Keys are paths RELATIVE TO the configured root, exactly
# as S3 keys are relative to the bucket -- so the orchestrator and format
# are identical across backends.
#
# retrieve_index / publish_index / _slurp are PROVIDED by the role (they
# call fetch_object / save_object), so this engine implements only the
# seven required primitives:
#   new list_distributions fetch_object save_object has_object lock base_url
#
# Config shape (in the DarkPAN entry):
#   storage => { type => 'Filesystem', root => '/srv/darkpan' }
#   url     => 'http://localhost:8080'   # optional public base for reads
#
# This is the credential-free, network-free backend: it doubles as the
# test harness for the whole indexer and as the laptop-runnable demo.

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use File::Basename qw(dirname);
use File::Find qw(find);
use File::Path qw(make_path);
use File::Spec;
use Fcntl qw(:flock);

use Role::Tiny::With;
with 'DarkPAN::Indexer::Storage';

########################################################################
sub new {
########################################################################
  my ( $class, $config ) = @_;

  my %storage = %{ $config->{storage} // {} };

  my $root = $storage{root};

  croak "Filesystem storage: root is required\n"
    if !defined $root || $root eq q{};

  croak "Filesystem storage: root '$root' is not a directory\n"
    if !-d $root;

  my $self = bless {
    config   => $config,
    root     => $root,
    prefix   => $storage{prefix},  # optional scan sub-root under root
    base_url => $config->{url},  # optional public base for the resolver
  }, $class;

  return $self;
}

########################################################################
sub base_url { return $_[0]->{base_url} }
########################################################################

########################################################################
# _abs($key) -> absolute path for a root-relative key.
########################################################################
sub _abs {
########################################################################
  my ( $self, $key ) = @_;

  return File::Spec->catfile( $self->{root}, $key );
}

########################################################################
# list_distributions() -> root-relative keys of .tar.gz files under the
# configured prefix (or the whole root if no prefix). Same domain filter
# as the S3 engine: this seam owns "what counts as a distribution".
########################################################################
sub list_distributions {
########################################################################
  my ($self) = @_;

  my $scan_root
    = defined $self->{prefix}
    ? File::Spec->catdir( $self->{root}, $self->{prefix} )
    : $self->{root};

  return
    if !-d $scan_root;

  my @keys;

  find(
    { no_chdir => 1,
      wanted   => sub {
        my $path = $File::Find::name;
        return if !-f $path;
        return if $path !~ m{[.]tar[.]gz\z}xsm;

        # convert absolute path back to a root-relative key
        my $key = File::Spec->abs2rel( $path, $self->{root} );
        push @keys, $key;
      },
    },
    $scan_root,
  );

  return @keys;
}

########################################################################
# fetch_object($key) -> raw bytes, or undef if genuinely absent.
# A real read error (exists but unreadable) throws.
########################################################################
sub fetch_object {
########################################################################
  my ( $self, $key ) = @_;

  my $path = $self->_abs($key);

  return
    if !-e $path;  # not found -> undef (matches S3 semantics)

  open my $fh, '<', $path
    or croak "Filesystem storage: cannot read '$path': $OS_ERROR\n";
  binmode $fh;

  local $RS = undef;
  my $content = <$fh>;

  close $fh
    or croak "Filesystem storage: cannot close '$path': $OS_ERROR\n";

  return $content;
}

########################################################################
# has_object($key) -> boolean.
########################################################################
sub has_object {
########################################################################
  my ( $self, $key ) = @_;

  return -e $self->_abs($key) ? 1 : 0;
}

########################################################################
# save_object($key, $bytes, %opts) -> writes bytes at $key, creating
# intermediate directories. content_type is accepted for contract
# symmetry with S3 but has no meaning on a filesystem.
########################################################################
sub save_object {
########################################################################
  my ( $self, $key, $content, %opts ) = @_;

  my $path = $self->_abs($key);
  my $dir  = dirname($path);

  if ( !-d $dir ) {
    make_path($dir)
      or croak "Filesystem storage: cannot create '$dir': $OS_ERROR\n";
  }

  open my $fh, '>', $path
    or croak "Filesystem storage: cannot write '$path': $OS_ERROR\n";
  binmode $fh;

  print {$fh} $content
    or croak "Filesystem storage: write failed for '$path': $OS_ERROR\n";

  close $fh
    or croak "Filesystem storage: cannot close '$path': $OS_ERROR\n";

  return 1;
}

########################################################################
# lock($key, %opts) -> a GUARD on success, false on failure.
#
# Same contract as the S3 engine: bind the return to a lexical; the guard
# releases (unlocks + closes) in DESTROY when it leaves scope, including
# on die. Mechanism here is flock on a "<key>.lock" file under the root.
#
# %opts: wait (seconds to block for the lock; 0 = non-blocking, fail fast).
# ttl is accepted for contract symmetry but is not meaningful for flock --
# the OS releases the lock if the holder dies, so there is no stale lock
# to time out.
########################################################################
sub lock {
########################################################################
  my ( $self, $key, %opts ) = @_;

  my $wait = $opts{wait} // 0;

  my $lock_path = $self->_abs("$key.lock");
  my $dir       = dirname($lock_path);

  make_path($dir) if !-d $dir;

  open my $fh, '>', $lock_path
    or croak "Filesystem storage: cannot open lock '$lock_path': $OS_ERROR\n";

  my $mode = $wait ? LOCK_EX : ( LOCK_EX | LOCK_NB );

  if ($wait) {
    # block up to $wait seconds using an alarm, so we don't hang forever
    my $got = eval {
      local $SIG{ALRM} = sub { die "timeout\n" };
      alarm $wait;
      my $ok = flock $fh, LOCK_EX;
      alarm 0;
      return $ok;
    };
    if ( !$got ) {
      close $fh;
      return;  # could not acquire within wait
    }
  }
  else {
    if ( !flock $fh, LOCK_EX | LOCK_NB ) {
      close $fh;
      return;  # held by someone else, non-blocking
    }
  }

  return DarkPAN::Indexer::Storage::Filesystem::Guard->new(
    fh   => $fh,
    path => $lock_path,
  );
}

########################################################################
package DarkPAN::Indexer::Storage::Filesystem::Guard;
########################################################################
# RAII flock guard. True while held; releases (unlock, close, unlink) on
# DESTROY. flock is advisory and OS-released on process exit, so unlike
# the S3 guard there is no stolen-lock hazard -- a dead holder's lock is
# freed by the kernel.

use strict;
use warnings;

use Fcntl qw(:flock);

sub new {
  my ( $class, %args ) = @_;
  return bless { %args, released => 0 }, $class;
}

sub release {
  my ($self) = @_;

  return if $self->{released};
  $self->{released} = 1;

  if ( $self->{fh} ) {
    flock $self->{fh}, LOCK_UN;
    close $self->{fh};
  }

  # best-effort cleanup of the lockfile; harmless if another waiter
  # recreated it.
  unlink $self->{path} if $self->{path} && -e $self->{path};

  return;
}

sub DESTROY {
  my ($self) = @_;
  return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
  $self->release;
  return;
}

1;
