package My::SessionAuthorizor;

use Apache::Constants qw(OK AUTH_REQUIRED);

use Apache::AuthDigest::API::Session;

use strict;

sub handler {

  my $r = Apache::AuthDigest::API::Session->new(shift);

  my ($key, $session) = $r->get_session;

  return OK unless $session eq 'c4bfb2a0bab0e91bc7dcfbe3bbec246e';

  $r->note_digest_auth_failure;
  return AUTH_REQUIRED;
}

1;
