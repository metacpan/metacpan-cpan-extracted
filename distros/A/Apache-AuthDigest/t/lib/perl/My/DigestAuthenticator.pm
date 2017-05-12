package My::DigestAuthenticator;

use Apache::Constants qw(OK DECLINED AUTH_REQUIRED);

use Apache::AuthDigest::API;

use strict;

sub handler {

  my $r = Apache::AuthDigest::API->new(shift);

  return DECLINED unless $r->is_initial_req;

  my ($status, $response) = $r->get_digest_auth_response;

  return $status unless $status == OK;

  my $digest = get_credentials($r->user, $r->auth_name);

  # for other testing purposes...
  $r->pnotes(URI => $response->{uri});

  return OK if $r->compare_digest_response($response, $digest);

  $r->note_digest_auth_failure;
  return AUTH_REQUIRED;
}

sub get_credentials {

  my ($user, $realm) = @_;

  # this represents a routine that fetches the Digest::MD5 hash of
  # the credentials for user $r->user at realm $r->auth_name
  
  # to generate your own credentials, use the htdigest utility
  # program that ships with Apache, or the Perl one-liner
  # $ perl -MDigest::MD5 -e'print Digest::MD5::md5_hex("user:realm:password"),"\n"'

  return '966b699e9ada71dbefb7276e0fc1aaf1';
}
1;
