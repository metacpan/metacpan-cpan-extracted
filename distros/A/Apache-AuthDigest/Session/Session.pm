package Apache::AuthDigest::API::Session;

use Apache::Log;
use Apache::ModuleConfig;

use Apache::AuthDigest::API;

use 5.006;
use DynaLoader;

use strict;

our $VERSION = '0.01';
our @ISA = qw(DynaLoader Apache::AuthDigest::API);

__PACKAGE__->bootstrap($VERSION);

sub note_digest_auth_failure {

  my $r = shift;

  my $log = $r->server->log;

  my $cfg = Apache::ModuleConfig->get($r, __PACKAGE__);

  my $key = $cfg->{_session};

  my $nonce = $r->notes($key);

  unless ($nonce) {
    $log->info('Apache::AuthDigest::API::Session - no session found for ',
               "session key $key, using default request time instead");

    return $r->SUPER::note_digest_auth_failure;
  }

  $log->info("Apache::AuthDigest::API::Session - using notes() key $key ",
             "with session $nonce");

  my $auth_name = $r->auth_name;
  my $header_type = $r->proxyreq ? 'Proxy-Authenticate' : 'WWW-Authenticate';

  my $header_info = qq!Digest realm="$auth_name", nonce="$nonce"!;
                       

  $r->err_headers_out->set($header_type => $header_info);
}

sub compare_digest_response {

  my $r = shift;

  my $rc = $r->SUPER::compare_digest_response(@_);

  return unless $rc;

  my ($key, $session) = $r->get_session;

  $r->notes($key => $session);

  return $rc;
}

sub set_session {

  my ($r, $session) = @_;

  my $log = $r->server->log;

  my $cfg = Apache::ModuleConfig->get($r, __PACKAGE__);

  my $key = $cfg->{_session};

  $r->notes($key => $session);
}

sub get_session {

  my $r = shift;

  my $log = $r->server->log;

  my $cfg = Apache::ModuleConfig->get($r, __PACKAGE__);

  my $key = $cfg->{_session};

  my $response = $r->parse_digest_header;

  return ($key, $response->{nonce});

}

sub DigestSessionKey ($$$) {

  my ($cfg, $parms, $arg) = @_;

  $cfg->{_session} = $arg;
}

sub DIR_CREATE {
  # Initialize an object instead of using the mod_perl default.

  my $class = shift;
  my %self  = ();

  $self{_session} = 'AuthDigestSession';

  return bless \%self, $class;
}

sub DIR_MERGE {
  # Allow the subdirectory to inherit the configuration
  # of the parent, while overriding with anything more specific.

  my ($parent, $current) = @_;

  my %new = (%$parent, %$current);

  return bless \%new, ref($parent);
}

1;

__END__

=head1 NAME

Apache::AuthDigest::API::Session - session-based Digest authentication

=head1 SYNOPSIS

  PerlModule Apache::AuthDigest::API::Session
  PerlModule My::SessionAuthenticator

  <Location /protected>
    PerlInitHandler My::SessionGenerator
    PerlAuthenHandler My::SessionAuthenticator
    Require valid-user
    AuthType Digest
    AuthName "cookbook"
    DigestSessionKey MYSESSION
  </Location>

=head1 DESCRIPTION

Apache::AuthDigest::API::Session is an experimental interface
for using the "nonce" part of Digest authentication as
a unique session identifier.  For more information on Digest
authentication, see RFC 2617:
  ftp://ftp.isi.edu/in-notes/rfc2617.txt

Apache::AuthDigest::API::Session is a subclass of Apache::AuthDigest::API,
so see that manpage for details on the base API.  where they 
differ is in the "nonce" key that is used to keep track of
authentication sessions.  Apache::AuthDigest::API uses the default
Apache nonce (currently r->request_time).  
Apache::AuthDigest::API::Session uses whatever is stored in
$r->notes($key), where $key is the notes key specified by 
the DigestSessionKey configuration directive (which defaults to
'SESSION').

How this all works together is still taking shape.  the RFC says 
that a new nonce should be generated for each 401 sent by the server
in order to prevent a replay attack.  To me, that sounds rather like
what we tend to do with cookies: initiate a session, store it on the
client, retrieve the session on each request, then finally expire the
session.

With Digest authentication, session initialization is taken care of
with the initial 401 response, when the server generates a nonce.
here, the session is initalized with the value in $r->notes('SESSION').
the session is stored on the client and sent along with every request
to the same realm in the Authorization header.  Apache::AuthDigest::API::Session
provides the get_session() method for gleaning the session from the
headers.  So, all we're left with is expiring the session...

How I think this has to work is that $r->notes('SESSION') has to have
a dual meaning.  Prior to the PerlAuthenHandler, it needs to hold
a _new_ session identifier - whatever the session would be if the 
user was coming in fresh with no session id.  After the user authenticates,
we can use $r->notes('SESSION') to store the session id of the
authenticated user.  this session can then be used by a PerlAuthzHandler
(or other similar mechansim) to determine the validity of the session.

So, this means that the developer needs to do a few things.  First,
each request (via a PerlInitHandler or whatever) needs to populate
$r->notes('SESSION') with a session to be used _if the user cannot
authenticate_.  If you think through how HTTP authentication and the
Apache API works, you'll see why this needs to happen on every 
request (or correct me if you think I'm wrong). compare_digest_response()
will then, if the user credentials check out, populate $r->notes('SESSION') 
with the session identifier that the user passed back via the headers.

So, when the PerlAuthzHandler, PerlFixupHandler and
PerlHandler are run, $r->notes('SESSION') is the real session id, 
as gleaned from the headers, and _not_ what was placed into it by
the user via a PerlInitHandler or whatever other mechanism one uses
to generate a session.

an alternative interface is to have any handler that wants
the current session identifier instantiate a new 
Apache::AuthDigest::API::Session object and call get_session() on
it instead of diddling with $r->notes().  

as this unfolds and people start to see what is going on, it will
probably take more shape.  There may very well be security implications
here that I can't see, so beware.  Hopefully if there are they will
be flushed out through the community.

=over 4

=item new()

creates a new Apache::AuthDigest::API::Session object.  Apache::DigestAPI is a
subclass of the Apache class so, with the exception of the addition
of new methods, $r can be used the same as if it were a normal
Apache object

  my $r = Apache::AuthDigest::API::Session->new(Apache->request);

=item get_session()

returns a list.  the first element is the notes key as defined by
DigestSessionKey.  the second element is the session identifier (if
obtainable).

  my ($key, $session) = $r->get_session;

=item set_session()

set the session.  this actually is an interface that abstracts the
notes() stuff I mentioned earlier. 

  $r->set_session($session);

=item compare_digest_response()

same as Apache::AuthDigest::API, except that the nonce value is placed in
$r->notes if the comparison is successful.

=back

=head1 EXAMPLE

for a complete example, see the My/SessionAuthenticator.pm file
in the test suite for this package.

=head1 SEE ALSO

perl(1), mod_perl(1), Apache(3)

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
