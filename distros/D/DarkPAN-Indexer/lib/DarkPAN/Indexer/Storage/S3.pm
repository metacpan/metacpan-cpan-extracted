package DarkPAN::Indexer::Storage::S3;

# S3 storage engine for DarkPAN::Indexer.
#
# Consumes the DarkPAN::Indexer::Storage role (the contract). Wraps the
# four S3 primitives the old roles called directly:
#   list_objects_v2  -> list_distributions
#   get_object       -> fetch_object
#   head_object      -> has_object
#   put_object       -> save_object
#
use strict;
use warnings;

use Amazon::Credentials;
use Amazon::S3::Lite;
use Amazon::S3::Lite::Lock;
use Data::Dumper;
use Carp qw(croak);
use English qw(-no_match_vars);

use Role::Tiny::With;
with 'DarkPAN::Indexer::Storage';  # requires: list_distributions fetch_object
  #           save_object has_object lock base_url

caller or exit __PACKAGE__->main();

########################################################################
sub new {
########################################################################
  my ( $class, $config ) = @_;

  # prefer storage keys over AWS
  my %storage = ( %{ $config->{AWS} // {} }, %{ $config->{storage} // {} } );
  $storage{region} //= $ENV{AWS_REGION} // 'us-east-1';

  $config->{storage} = \%storage;

  croak "S3 storage: bucket is required\n"
    if !defined $storage{bucket} || $storage{bucket} eq q{};

  my $self = bless {
    config   => $config,
    bucket   => $storage{bucket},
    prefix   => $storage{prefix},
    region   => $storage{region},
    profile  => $storage{profile},
    base_url => $config->{url},  # public (CloudFront) base
  }, $class;

  return $self;
}

########################################################################
sub _s3 {
########################################################################
  my ($self) = @_;

  return $self->{s3} //= Amazon::S3::Lite->new(
    { region      => $self->{region},
      credentials => Amazon::Credentials->new( profile => $self->{profile} ),
    }
  );
}

########################################################################
sub base_url { return $_[0]->{base_url} }
########################################################################

########################################################################
# list_distributions() -> list of keys (relative to the bucket) that
# look like distribution tarballs under the configured prefix. Paginates
# via continuation token. The .tar.gz filter lives here because "what
# counts as a distribution" is the one bit of domain knowledge this
# seam legitimately owns.
########################################################################
sub list_distributions {
########################################################################
  my ($self) = @_;

  my $s3 = $self->_s3;
  my @keys;
  my $token;

  while (1) {
    my %options = ( defined $self->{prefix} ? ( prefix => $self->{prefix} ) : () );

    if ( defined $token ) {
      $options{continuation_token} = $token;
    }

    my $result = $s3->list_objects_v2( $self->{bucket}, %options );

    for my $object ( @{ $result->{objects} || [] } ) {
      my $key = $object->{key};
      next if !defined $key;
      next if $key !~ m{[.]tar[.]gz\z}xsm;
      push @keys, $key;
    }

    last
      if !$result->{is_truncated};

    $token = $result->{next_continuation_token};
    last if !$token;
  }

  return @keys;
}

########################################################################
# fetch_object($key) -> raw bytes, or undef if genuinely absent.
# A real I/O failure throws (fail-fast contract).
########################################################################
sub fetch_object {
  my ( $self, $key ) = @_;

  my $object = $self->_s3->get_object( $self->{bucket}, $key );

  return
    if !defined $object;  # not found -> undef

  return $object->{content};
}

########################################################################
# has_object($key) -> boolean. Wraps head_object.
########################################################################
sub has_object {
  my ( $self, $key ) = @_;

  return $self->_s3->head_object( $self->{bucket}, $key ) ? 1 : 0;
}

########################################################################
# save_object($key, $bytes, %opts) -> writes. %opts may carry
# content_type; caller (Utils) already gzips, so this moves bytes only.
########################################################################
sub save_object {
  my ( $self, $key, $content, %opts ) = @_;

  my $content_type = $opts{content_type} // 'application/octet-stream';

  return $self->_s3->put_object( $self->{bucket}, $key, $content, content_type => $content_type, );
}

########################################################################
# lock($key, %opts) -> a GUARD object on success, false on failure.
#
# CONTRACT (both engines must match): lock() acquires and returns a
# guard. The guard is true on success and releases the lock in its
# DESTROY when it goes out of scope â including on die. The caller MUST
# bind it to a lexical for the whole critical section:
#
#     my $guard = $storage->lock($key, ttl => 300, wait => 60)
#       or croak 'could not acquire packages index lock';
#     ... fetch -> mutate -> save ...
#     # $guard drops here -> release, even if the block died
#
# Discarding the return (void context, or letting it fall off the end of
# a block) releases the lock immediately and defeats the mutex. Hold it.
#
# S3 uses the conditional-PUT lock (Amazon::S3::Lite::Lock); its guard
# releases with If-Match on its own etag so it never clobbers a lock
# that was stolen after a TTL lapse. The Filesystem engine returns an
# flock-based guard instead â same contract, different mechanism.

########################################################################
sub lock {
########################################################################
  my ( $self, $key, %opts ) = @_;

  require Amazon::S3::Lite::Lock;

  # acquire() returns the guard on success, false if the lock is held
  # and could not be (stolen as stale / waited out).
  return Amazon::S3::Lite::Lock->new(
    s3     => $self->_s3,
    bucket => $self->{bucket},
    key    => $key,
    ttl    => $opts{ttl}  // 300,
    wait   => $opts{wait} // 0,
  )->acquire;
}

########################################################################
sub main {
########################################################################
  my $config_file = shift @ARGV;

  require JSON;

  open my $fh, '<', $config_file
    or die "ERROR: could not open $config_file for reading\n$OS_ERROR";

  my $config;

  {
    local $RS = undef;
    $config = JSON->new->decode(<$fh>);
    close $fh;
  }

  my $s3_storage = __PACKAGE__->new( $config->{bedrock} );

  print Dumper( [ distributions => $s3_storage->list_distributions ] );

  return 0;
}

1;
