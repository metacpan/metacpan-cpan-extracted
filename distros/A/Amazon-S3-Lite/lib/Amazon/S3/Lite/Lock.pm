package Amazon::S3::Lite::Lock;

# Mutual exclusion over an S3 object, built on Amazon::S3::Lite's
# conditional-header support (If-None-Match / If-Match) and last_status.
#
# The correctness rests on three server-side atomic operations:
#   acquire     PUT If-None-Match:*        -> 200 win / 412 held
#   steal-stale PUT If-Match:<stale-etag>  -> 200 win / 412 someone-beat-me
#   release     DELETE If-Match:<my-etag>  -> only ever deletes MY lock
#
# The lock object's body carries an expiry timestamp written by the
# holder, so "is it stale?" is judged against a deadline the holder
# set, not against each waiter's own clock.
#
# acquire() returns a guard object; when the guard goes out of scope
# (normal return OR die), DESTROY releases the lock. TTL/steal-stale
# is the backstop for hard kills where DESTROY never runs.

use strict;
use warnings;

use Carp qw(croak);
use English qw(-no_match_vars);
use JSON qw(encode_json decode_json);

########################################################################
sub new {
########################################################################
  my ( $class, %args ) = @_;

  my $self = bless {
    s3     => $args{s3},  # Amazon::S3::Lite instance (required)
    bucket => $args{bucket},  # required
    key    => $args{key}   // 'locks/default.lock',
    ttl    => $args{ttl}   // 120,  # seconds a lock is considered fresh
    owner  => $args{owner} // sprintf( '%s@%s', $PID, $ENV{HOSTNAME} // 'unknown' ),
    wait   => $args{wait}  // 0,  # seconds to block waiting; 0 = no wait
    poll   => $args{poll}  // 2,  # seconds between acquire retries
  }, $class;

  croak 's3 is required'
    if !$self->{s3};

  croak 'bucket is required'
    if !$self->{bucket};

  return $self;
}

########################################################################
sub acquire {
########################################################################
  my ($self) = @_;

  # Try to create the lock only if absent. On 412 the lock is held;
  # decide whether it's stale and, if so, steal it. Optionally block
  # up to {wait} seconds, polling every {poll}.
  my $deadline = time + $self->{wait};

  while (1) {
    my $etag = $self->_try_create;  # 200 -> etag, 412 -> undef
    return $self->_guard($etag) if $etag;

    # Held. Is it stale?
    my $stolen = $self->_try_steal_if_stale;  # 200 -> etag, else undef
    return $self->_guard($stolen) if $stolen;

    last if time >= $deadline;  # no-wait or timed out
    sleep $self->{poll};
  }

  return;  # could not acquire (caller checks truthiness)
}

########################################################################
sub _try_create {
########################################################################
  my ($self) = @_;

  my $body = encode_json( { owner => $self->{owner}, expires => time + $self->{ttl} } );

  my $etag = eval {
    $self->{s3}->put_object(
      $self->{bucket}, $self->{key}, $body,
      content_type => 'application/json',
      headers      => { 'If-None-Match' => q{*} },
    );
  };

  my $err = $EVAL_ERROR;

  return $etag
    if $self->{s3}->last_status =~ /\A2/xsm;  # acquired

  return
    if $self->{s3}->last_status == 412;  # held by someone

  die $err;  # real error
}

########################################################################
sub _try_steal_if_stale {
########################################################################
  my ($self) = @_;

  # Read current lock: need its ETag + expiry.
  my $meta = eval { $self->{s3}->head_object( $self->{bucket}, $self->{key} ) };

  return
    if !$meta;  # vanished â next loop's create will win

  my $current_etag = $meta->{etag};

  # Fetch body to read the holder's expiry (head doesn't carry it).
  my $obj  = eval { $self->{s3}->get_object( $self->{bucket}, $self->{key} ) };
  my $data = eval { decode_json( $obj->{content} // '{}' ) } // {};

  return
    if ( $data->{expires} // 0 ) > time;  # still fresh â don't steal

  # Stale. Steal ONLY if the lock is still the exact one we judged stale.
  my $body = encode_json( { owner => $self->{owner}, expires => time + $self->{ttl} } );

  my $etag = eval {
    $self->{s3}->put_object(
      $self->{bucket}, $self->{key}, $body,
      content_type => 'application/json',
      headers      => { 'If-Match' => $current_etag },
    );
  };

  return $etag
    if $self->{s3}->last_status =~ /\A2/xsm;  # stole it

  return;  # someone beat us (412) â retry loop
}

########################################################################
sub _guard {
########################################################################
  my ( $self, $etag ) = @_;

  return Amazon::S3::Lite::Lock::Guard->new(
    s3     => $self->{s3},
    bucket => $self->{bucket},
    key    => $self->{key},
    etag   => $etag,  # so release only deletes OUR lock
  );
}

1;
