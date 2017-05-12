package Algorithm::SpatialIndex::Storage::Redis;
use 5.008001;
use strict;
use warnings;
use Carp qw(confess);

our $VERSION = '0.01';

use Scalar::Util qw(blessed);
use Redis;

use parent 'Algorithm::SpatialIndex::Storage';
use Sereal::Encoder;
use Sereal::Decoder;

use Class::XSAccessor {
  getters => {
    _conn    => 'redisconn',
    _prefix  => 'prefix',
    _encoder => 'encoder',
    _decoder => 'decoder',
  },
};

sub init {
  my $self = shift;
  my $opt = $self->{opt}{redis};

  # Determine key prefix
  my $prefix = $opt->{prefix};
  confess("Need Redis key name prefix for Redis storage backend")
    if not defined $prefix;
  $self->{prefix} = $prefix;

  # Setup (de)serializers
  my $enc = $opt->{encoder};
  if (blessed($enc)) {
    $self->{encoder} = $enc;
  }
  else {
    $self->{encoder} = Sereal::Encoder->new(ref($enc) eq 'HASH' ? $enc : ());
  }
  my $dec = $opt->{decoder};
  if (blessed($dec)) {
    $self->{decoder} = $dec;
  }
  else {
    $self->{decoder} = Sereal::Decoder->new(ref($dec) eq 'HASH' ? $dec : ());
  }

  # Connect to Redis
  my $conn = $opt->{conn};
  if (blessed($conn)) {
    $self->{redisconn} = $conn;
  }
  else {
    $self->{redisconn} = Redis->new(%$conn);
  }

  # Assert state of data in Redis
  $conn = $self->_conn;
  my $type;
  $type = $conn->type($prefix . "_options");
  if ($type eq "hash" || $type eq "none") {
    # fine
  } else {
    confess("Key for option storage in Redis (${prefix}_options) is of incompatible type");
  }

  $type = $conn->type($prefix . "_buckets");
  if ($type eq "hash" || $type eq "none") {
    # fine
  } else {
    confess("Key for bucket storage in Redis (${prefix}_buckets) is of incompatible type");
  }

  $type = $conn->type($prefix . "_nodes");
  if ($type eq "hash" || $type eq "none") {
    # fine
  } else {
    confess("Key for node storage in Redis (${prefix}_nodes) is of incompatible type");
  }
}

sub get_option {
  my $self = shift;
  return $self->_conn->hget($self->_prefix . "_options", shift);
}

sub set_option {
  my ($self, $key, $value) = @_;
  $self->_conn->hset($self->_prefix . "_options", $key, $value);
  return 1;
}

sub fetch_node {
  my ($self, $index) = @_;

  my $node = $self->_conn->hget($self->_prefix . "_nodes", $index);
  return() if not defined $node;
  return $self->_decoder->decode($node);
}

sub store_node {
  my ($self, $node) = @_;

  my $id = $node->id;
  my $conn = $self->_conn;
  my $key = $self->_prefix . "_nodes";
  if (not defined $id) {
    $id = $conn->hincrby($key, "top_id", 1);
    $node->id($id);
  }

  my $str = $self->_encoder->encode($node);
  $conn->hset($key, $id, $str);

  return $id;
}

sub store_bucket {
  my ($self, $bucket) = @_;

  my $str = $self->_encoder->encode($bucket);
  $self->_conn->hset($self->_prefix . "_buckets", $bucket->node_id, $str);
  return 1;
}

sub fetch_bucket {
  my ($self, $node_id) = @_;

  my $str = $self->_conn->hget($self->_prefix . "_buckets", $node_id);
  return() if not defined $str;
  return $self->_decoder->decode($str);
}

sub delete_bucket {
  my ($self, $node_id) = @_;

  $node_id = $node_id->node_id if ref($node_id);
  $self->_conn->hdel($self->_prefix . "_buckets", $node_id);

  return();
}

sub remove_all {
  my $self = shift;
  my $conn = $self->_conn;
  my $prefix = $self->_prefix;
  $conn->del($prefix . "_options");
  $conn->del($prefix . "_nodes");
  $conn->del($prefix . "_buckets");
}


1;
__END__

=head1 NAME

Algorithm::SpatialIndex::Storage::Redis - Redis storage backend

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    storage => 'Redis',
    redis => {
      conn => $redisconn, # or Redis.pm ->new parameters
      prefix => "my_redis_key_prefix",
      # Optional:
      encoder => $sereal_encoder, # or hashref with options
      decoder => $sereal_decoder, # or hashref with options
    },
  );

=head1 DESCRIPTION

Inherits from L<Algorithm::SpatialIndex::Storage>.

=head1 METHODS

On top of the methods required by C<Algorithm::SpatialIndex::Storage>,
this storage backend implements the following:

=head2 remove_all

Deletes all related spatial-index data from Redis.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
