package Amazon::S3::Lite::Lock::Guard;
########################################################################
# RAII release: DESTROY deletes the lock, but only if it's still ours
# (If-Match on the etag we acquired). Handles normal scope-exit and
# exceptions; the TTL/steal path covers hard kills where DESTROY
# never fires.

use strict;
use warnings;

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
  eval {
    $self->{s3}->delete_object(
      $self->{bucket}, $self->{key},
      headers => { 'If-Match' => $self->{etag} },  # <-- needs delete_object to accept headers
    );
  };

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
