package Apache::AuthDigest::API;

use Apache;
use Apache::Log;
use Apache::Constants qw(OK DECLINED SERVER_ERROR AUTH_REQUIRED);

use 5.006;
use Digest::MD5;
use HTTP::Headers::Util qw(split_header_words);
use DynaLoader;

use strict;

our $VERSION = '0.021';
our @ISA = qw(DynaLoader Apache);

__PACKAGE__->bootstrap($VERSION);

sub new {

  my ($class, $r) = @_;

  $r ||= Apache->request;

  return bless { r => $r }, $class;
}

sub get_digest_auth_response {

  my $r = shift;

  my $log = $r->server->log;

  my $auth_type = $r->auth_type;
  my $auth_name = $r->auth_name;

  # Check that we're supposed to be handling this.
  unless (lc($auth_type) eq 'digest') {
    $log->info("AuthType $auth_type not supported by ", ref($r));
    return DECLINED;
  }

  # Check that AuthName was set.
  unless ($auth_name) {
    $log->error("AuthName not set");
    return SERVER_ERROR;
  }

  my $response = $r->parse_digest_header;

  unless ($response) {
    $log->info("Client did not supply a Digest response");

    $r->note_digest_auth_failure;
    return AUTH_REQUIRED;
  }
  
  # Make sure that the response contained all the right info.
  foreach my $key (qw(username realm nonce uri response)) {
    unless ($response->{$key}) {
      $log->warn("Required key '$key' not present in response");
  
      $r->note_digest_auth_failure;
      return AUTH_REQUIRED;
    }
  }

  # Ok, we're good to go. Set some info for the request
  # and return the response information so it can be checked.
  $r->user($response->{username});
  $r->connection->auth_type('Digest');

  return (OK, $response);
}

sub compare_digest_response {
  # Compare a response hash from get_digest_auth_response()
  # against a pre-calculated digest (e.g., a3165385201a7ba52a12e88cb606bc76).

  my ($r, $response, $digest) = @_;

  my $md5 = Digest::MD5->new;

  $md5->add(join ":", ($r->method, $response->{uri}));

  $md5->add(join ":", ($digest, $response->{nonce}, $md5->hexdigest));

  return $response->{response} eq $md5->hexdigest;
}

# this is not part of the official API
sub parse_digest_header {

  my $r = shift;

  my $log = $r->server->log;

  # Get the response to the Digest challenge.
  my $header_type = $r->proxyreq ? 'Proxy-Authorization' : 'Authorization';

  my $header_info = $r->headers_in->get($header_type);

  $log->info("Apache::AuthDigest::API - parsing $header_type: $header_info");

  # ease my pain
  my @parsed_header = split_header_words($header_info);

  my %response = map { $_->[0] => $_->[1] } @parsed_header;

  # take care of the first attribute, which is stuck in with Digest
  $response{$parsed_header[0]->[2]} = $parsed_header[0]->[3];

  # We issued a Digest challenge - make sure we got Digest back.
  return unless exists $response{Digest};
    
  return \%response;
}

1;

__END__

=head1 NAME

Apache::AuthDigest::API - mod_perl API for Digest authentication

=head1 SYNOPSIS

  PerlModule Apache::AuthDigest::API
  PerlModule My::DigestAuthenticator

  <Location /protected>
    PerlAuthenHandler My::DigestAuthenticator
    Require valid-user
    AuthType Digest
    AuthName "cookbook"
  </Location>

=head1 DESCRIPTION

Apache::AuthDigest::API is a simple API for interacting with 
Digest authentication.  For more information on Digest
authentication, see RFC 2617:
  ftp://ftp.isi.edu/in-notes/rfc2617.txt

The API itself is very similar to the API mod_perl offers
natively for Basic authentication:

  mod_perl's Basic support       AuthDigest::API equivalent

    my $r = shift;                 $r = Apache::AuthDigest::API->new(shift)

    $r->get_basic_auth_pw()        $r->get_digest_auth_response()       

    $r->note_basic_auth_failure    $r->note_digest_auth_failure()

    [none]                         $r->compare_digest_response()

see Recipe 13.8 in the mod_perl Developer's Cookbook for a far more
detailed explanantion than will be covered here.

=over 4

=item new()

creates a new Apache::AuthDigest::API object.  Apache::AuthDigest::API
is a subclass of the Apache class so, with the exception of the
addition of new methods, $r can be used the same as if it were a
normal Apache object

  my $r = Apache::AuthDigest::API->new(Apache->request);

=item get_digest_auth_response()

this parses out the authentication header sent by the client.  it
returns a status and a reference to a hash representing the 
client Digest request (if any).

  my ($status, $response) = $r->get_digest_auth_response;
  return $status unless $status == OK;

=item note_digest_auth_failure()

sets the proper authentication headers which prompt a client to 
send a proper Digest request in order to access the requested
resource.

  $r->note_digest_auth_failure;
  return AUTH_REQUIRED;

=item compare_digest_response()

this method represents a shortcut for comparing a client Digest
request with whatever credentials are stored on the server.  the
first argument is the hash reference returned by 
get_digest_auth_response().  the second argument is a MD5 digest
of the user credentials.  the credentials should be in the form

  user:realm:password 

before they are hashed.  the following Perl one-liner will generate
a suitable digest:

  $ perl -MDigest::MD5 -e'print Digest::MD5::md5_hex("user:realm:password"),"\n"'

=back

=head1 EXAMPLE

for a complete example, see the My/DigestAuthenticator.pm file
in the test suite for this package, as well as AuthDigest.pm.
In general, the steps are the same as for Basic authentication, 
examples of which abound on CPAN, the Eagle book, and the Cookbook:

  use Apache::AuthDigest::API;

  sub handler {

    my $r = Apache::AuthDigest::API->new(shift);

    my ($status, $response) = $r->get_digest_auth_response;

    return $status unless $status == OK;

    my $digest = my_get_user_credentials_routine($r->user, $r->auth_name);

    return OK if $r->compare_digest_response($response, $digest);

    $r->note_digest_auth_failure;
    return AUTH_REQUIRED;
  }

=head1 NOTES

this module essentially mimics the Digest implementation provided
by mod_digest.c that ships with Apache.  there is another
implementation, classified as "experimental" that also ships with
Apache, mod_auth_digest.c, which is more complete wrt RFC 2617.
of particular interest is that the mod_digest implementation does
not work with MSIE (so neither does this implemenation).  at some
point, Apache::AuthDigest::API::Full will implement a completely
compliant API - this will have to do for now.

=head1 FEATURES/BUGS

none that I know of yet, but consider this alphaware.

=head1 SEE ALSO

perl(1), mod_perl(1), Apache(3), Apache::AuthDigest(3)

=head1 AUTHORS

Geoffrey Young E<lt>geoff@modperlcookbook.orgE<gt>

Paul Lindner E<lt>paul@modperlcookbook.orgE<gt>

Randy Kobes E<lt>randy@modperlcookbook.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2002, Geoffrey Young, Paul Lindner, Randy Kobes.  

All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 HISTORY

This code is derived from the I<Cookbook::DigestAPI> module,
available as part of "The mod_perl Developer's Cookbook".

For more information, visit http://www.modperlcookbook.org/

=cut
