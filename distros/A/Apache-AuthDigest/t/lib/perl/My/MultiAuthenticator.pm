package My::MultiAuthenticator;

use Apache::Constants qw(OK DECLINED AUTH_REQUIRED);

use Apache::AuthDigest::API::Multi;

use strict;

sub handler {

  my $r = Apache::AuthDigest::API::Multi->new(shift);

  $r->note_basic_auth_failure;
  $r->note_digest_auth_failure;

  return AUTH_REQUIRED;
}

1;
