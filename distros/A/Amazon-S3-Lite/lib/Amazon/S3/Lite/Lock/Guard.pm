package Amazon::S3::Lite::Lock::Guard;
########################################################################
# RAII release: DESTROY deletes the lock, but only if it's still ours
# (If-Match on the etag we acquired). Handles normal scope-exit and
# exceptions; the TTL/steal path covers hard kills where DESTROY
# never fires.

use strict;
use warnings;
use English qw(-no_match_vars);

########################################################################
sub new {
########################################################################
  my ( $class, %args ) = @_;
  return bless { %args, released => 0 }, $class;
}

########################################################################
sub release {
########################################################################
  my ($self) = @_;

  return
    if $self->{released};

  $self->{released} = 1;

  # DELETE If-Match:<our etag> â never clobber a lock that was stolen
  # from us after our TTL lapsed.
  my $ok = eval {
    my $etag = sprintf '"%s"', $self->{etag};
    $self->{s3}->delete_object(
      $self->{bucket}, $self->{key},
      headers => { 'If-Match' => $etag },  # <-- needs delete_object to accept headers
    );

    return 1;
  };

  my $err = $EVAL_ERROR;

  if ( !$ok ) {
    $self->{s3}->logger->debug(
      sprintf "lock release: bucket=%s key=%s etag=%s status=%s error=%s\n",
      $self->{bucket}, $self->{key},
      $self->{etag}            // q{},
      $self->{s3}->last_status // q{},
      $err                     // q{},
    );
  }

  return;
}

########################################################################
sub DESTROY {
########################################################################
  my ($self) = @_;

  return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
  $self->release;

  return;
}

1;
