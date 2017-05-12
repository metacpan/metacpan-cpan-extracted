# see doc at end of file

package Apache2::AuthenNTLM::Cookie;

use strict;
use warnings;

use Apache2::RequestRec        ();
use Apache2::Request;
use Apache2::Cookie;
use Apache2::Directive         ();
use Apache2::Const -compile => qw(OK HTTP_UNAUTHORIZED) ;
use Digest::SHA1               qw(sha1_hex);
use MIME::Base64               ();

use Apache2::AuthenNTLM;

our $VERSION = '1.02';

# constants from NTLM protocol
use constant NEGOTIATE_UNICODE     => 0x00000001;
use constant NEGOTIATE_NTLM        => 0x00000200;
use constant TARGET_TYPE_DOMAIN    => 0x00010000;
use constant NEGOTIATE_TARGET_INFO => 0x00800000;
use constant NTLM_SIGNATURE        => "NTLMSSP";
use constant NTLM_FORMAT           => "a8 V a8 V a8 a8 a8";

# named fields corresponding to format above
my @NTLM_FIELDS = qw/signature msg_type target_name flags 
                     challenge context target_info/;

# cookie format: digest(40); time_created(12); username
use constant COOKIE_FORMAT         => "A40 A12 A*"; 


sub handler : method  {
  my ($class, $r) = @_ ;

  # create an instance
  my $self = bless {
    request     => $r,
    secret      => $r->dir_config('secret')      || $class->default_secret,
    refresh     => $r->dir_config('refresh')     || 14400, # in seconds
    cookie_name => $r->dir_config('cookie_name') || 'NTLM_AUTHEN',
   }, $class;

  my $result;

  # get the cookie
  my $jar    = Apache2::Cookie::Jar->new($r);
  my $cookie = $jar->cookies($self->{cookie_name});
  my $has_valid_cookie = $cookie && $self->validate_cookie($cookie->value);

  # if cookie is present and valid
  if ($has_valid_cookie) {
    $result = Apache2::Const::OK;

    # if MSIE "optimization" is activated, i.e. if this is a POST with an
    # NTLM type1 message and without body ... 
    if ($r->method eq 'POST' && $self->has_empty_body && $self->is_NTLM_msg1) {

      # ... then we must fake a type2 msg so that MSIE will post again
      $r->log->debug("AuthenNTLM::Cookie: creating fake type2 msg");
      $self->add_auth_header($self->fake_NTLM_msg2);
      $result = Apache2::Const::HTTP_UNAUTHORIZED;
    }
  }

  # otherwise (if cookie is absent or invalid)
  else {

    # if no NTLM message, directly ask for authentication (avoid calling
    # Apache2::AuthenNTLM because it pollutes the error log)
    if (!$self->get_NTLM_msg && $self->is_ntlmauthoritative) {
      $self->ask_for_authentication;
      $result = Apache2::Const::HTTP_UNAUTHORIZED;
    }

    # else invoke Apache2::AuthenNTLM to go through the NTLM handshake    
    else {
      my $msg = $cookie ? "cookie invalidated" : "no cookie";
      $r->log->debug("AuthenNTLM::Cookie: $msg, calling Apache2::AuthenNTLM");
      $result = Apache2::AuthenNTLM->handler($r); # will set $r->user

      # create the cookie if NTLM succeeded
      $self->set_cookie if $result == Apache2::Const::OK;
    }
  }

  return $result;
}


sub validate_cookie {
  my ($self, $cookie_val) = @_;

  # unpack cookie information
  my ($sha, $time_created, $username) = unpack COOKIE_FORMAT, $cookie_val;

  # valid if not too old and matches the SHA1 digest
  my $now = time;
  my $is_valid 
    =  ($now - $time_created) < $self->{refresh}
    && $sha eq sha1_hex($time_created, $username, $self->{secret});

  # if valid, set the username
  $self->{request}->user($username) if $is_valid;

  $self->{request}->log->debug("cookie $cookie_val is " . 
                                 ($is_valid ? "valid" : "invalid"));
  return $is_valid;
}


sub set_cookie {
  my ($self) = @_;

  # prepare a new cookie from current time and current user
  my $r           = $self->{request};
  my $username    = $r->user; # was just set from the parent handler
  my $now         = time;
  my $sha         = sha1_hex($now, $username, $self->{secret});
  my $cookie_val  = pack COOKIE_FORMAT, $sha, $now, $username;
  my @cookie_args = (-name => $self->{cookie_name}, -value => $cookie_val);

  # other cookie args may come from apache config
 ARG:
  foreach my $arg (qw/expires domain path/) {
    my $val = $r->dir_config($arg) or next ARG;
    push @cookie_args, -$arg => $val;
  }

  # send cookie
  my $cookie = Apache2::Cookie->new($r, @cookie_args);
  $cookie->bake($r);

  $r->log->debug("AuthenNTLM::Cookie: baked cookie $cookie_val");
}


sub default_secret {
  my ($class) = @_;

  # default secret : mtime and i-node of Apache configuration file
  my $config_file     = Apache2::Directive::conftree->filename;
  my ($mtime, $inode) = (stat $config_file)[9, 1];
  return $mtime . $inode;
}


sub has_empty_body {
  my $self = shift;

  my $content_length = $self->{request}->headers_in->{"Content-Length"};
  if (defined $content_length && !$content_length) {
    return 1;
  }
  else {
    my $apr_req        = Apache2::Request->new($self->{request});
    my $body_apr_table = $apr_req->body;
    return !$body_apr_table || !scalar(keys %$body_apr_table);
  }
}


sub get_NTLM_msg {
  my $self         = shift;
  my $r            = $self->{request};
  my $header_field = $r->proxyreq ? 'Proxy-Authorization' : 'Authorization';
  my $auth_header  = $r->headers_in->{$header_field};

  if ($auth_header && $auth_header =~ s/^NTLM//) {
    my $packed = MIME::Base64::decode($auth_header);
    my %NTLM_msg;
    @NTLM_msg{@NTLM_FIELDS} = unpack NTLM_FORMAT, $packed;
    return \%NTLM_msg;
  }

  return;
}


sub is_NTLM_msg1 {
  my $self = shift;
  my $NTLM_msg = $self->get_NTLM_msg;
  return $NTLM_msg && $NTLM_msg->{msg_type} == 1;
}


sub fake_NTLM_msg2 {
  my $self = shift;

  my %NTLM_msg = (
    signature => NTLM_SIGNATURE,
    msg_type  => 2,
    flags     => NEGOTIATE_UNICODE  | NEGOTIATE_NTLM |
                 TARGET_TYPE_DOMAIN | NEGOTIATE_TARGET_INFO,
   );

  no warnings 'uninitialized';
  my $packed = pack NTLM_FORMAT, @NTLM_msg{@NTLM_FIELDS};

  return "NTLM " . MIME::Base64::encode($packed, '');
}


sub ask_for_authentication {
  my $self = shift;

  my $r      = $self->{request};
  my $auth_type = $r->auth_type || 'NTLM,Basic';

  $self->add_auth_header('NTLM') 
    if $auth_type =~ /\bNTLM\b/i;
  $self->add_auth_header(sprintf 'Basic realm="%s"', $r -> auth_name || '')
    if $auth_type =~ /\bBasic\b/i;
}


sub add_auth_header {
  my ($self, $header) = @_;

  my $r           = $self->{request};
  my $header_name = $r->proxyreq ? 'Proxy-Authenticate' : 'WWW-Authenticate';
  $r->err_headers_out->add($header_name => $header);
}


sub is_ntlmauthoritative {
  my $self = shift;

  my $r      = $self->{request};
  my $config = $r->dir_config('ntlmauthoritative') || 'on';
  return $config =~ /^(on|1)$/i;
}


1; # End of Apache2::AuthenNTLM::Cookie


__END__

=head1 NAME

Apache2::AuthenNTLM::Cookie - Store NTLM identity in a cookie

=head1 SYNOPSIS

  <Location /my/secured/URL>
    PerlAuthenHandler Apache2::AuthenNTLM::Cookie
    AuthType ntlm
    PerlAddVar ntdomain "domain primary_domain_controller other_controller"
    ...    # see other configuration params in Apache2::AuthenNTLM
  </Location>

=head1 DESCRIPTION

This module extends  L<Apache2::AuthenNTLM> with a cookie mechanism.

The parent module L<Apache2::AuthenNTLM> performs user authentication
via Microsoft's NTLM protocol; thanks to this mechanism, users are
automatically recognized from their Windows login, without having to
type a username and password. The server does not have to be a Windows
machine : it can be any platform, provided that it has access to a
Windows domain controller.  On the client side, both Microsoft
Internet Explorer and Mozilla Firefox implement the NTLM protocol.

The NTLM handshake involves several packet exchanges, and furthermore
requires serialization through an internal semaphore. Therefore, 
in order to improve performance, the present module saves the result
of that handshake in a cookie, so that the next request gets an
immediate answer.

A similar module was already published on CPAN for Apache1 / modperl1 
(L<Apache::AuthCookieNTLM>). The present module is an implementation
for Apache2 / modperl2, and has a a different algorithm for cookie
generation, in order to prevent any attempt to forge a fake cookie.

Details about the NTLM authentication protocol can be found at
L<http://davenport.sourceforge.net/ntlm.html#ntlmHttpAuthentication>.

=head1 CONFIGURATION

Configuration directives for NTLM authentication are 
just inherited from L<Apache2::AuthenNTLM>; see that module's
documentation. These are most probably all you need, namely
the minimal information for setting the handler, 
specifying the C<AuthType> and specifying the names
of domain controllers :

  <Location /my/secured/URL>
    PerlAuthenHandler Apache2::AuthenNTLM::Cookie
    AuthType ntlm
    PerlAddVar ntdomain "domain primary_domain_controller other_controller"
  </Location>

In addition to the inherited directives, some
optional C<PerlSetVar> directives 
allow you to control various details of cookie generation :

   PerlSetVar cookie_name my_cookie_name    # default is NTLM_AUTHEN
   PerlSetVar domain      my_cookie_domain  # default is none
   PerlSetVar expires     my_cookie_expires # default is none
   PerlSetVar path        my_cookie_path    # default is none
   PerlSetVar refresh     some_seconds      # default is 14400 (4 hours)
   PerlSetVar secret      my_secret_string  # default from stat(config file)

See L<Apache2::Cookie> for explanation of variables
C<cookie_name>, C<domain>, C<expires>, and C<path>.
The only variables specific to the present module are

=over

=item refresh

This is the number of seconds after which the cookie becomes invalid
for authentication : it complements the C<expires> parameter.  The
C<expires> value is a standard HTTP cookie mechanism which tells how
long a cookie will be kept on the client side; its default
value is 0, which means that this is a session cookie, staying as long
as the browser is open. But if the Windows account gets disabled,
the cookie will never reflect the new situation : therefore we 
must impose a periodic refresh of the cookie. The default refresh 
value is 14400 seconds (four hours).

=item secret

This is a secret phrase for generating a SHA1 digest that will be
incorporated into the cookie. The digest also incorporates the
username and cookie creation time, and is checked at each request :
therefore it is impossible to forge a fake cookie without knowing the
secret.

The default value for the secret is the concatenation of modification
time and inode of the F<httpd.conf> file on the server; therefore if
the configuration file changes, authentication cookies are
automatically invalidated.

=back

=head1 SPECIAL NOTE ABOUT INTERNET EXPLORER

Microsoft Internet Explorer (MSIE) has an "optimization" when sending
POST requests to an NTLM-secured site : the browser does not send the
request body because it expects to receive a 401 HTTP_UNAUTHORIZED
response, and then would send the body only at the second
request. This is a problem with the present module, because if
authorization is granted on the basis of a cookie, instead of NTLM
handshake, then control goes to the HTTP response handler ... but that
handler gets no parameters since the request body is empty !

One way to fix the problem is to set the registry entry 
C<HKEY_CURRENT_USER/Software/Microsoft/Windows/CurrentVersion/InternetSettings/DisableNTLMPreAuth>;
but this is only feasible if one has control over the registry settings of all clients.
Otherwise, the present module will forge a fake "NTLM type2" message, so that
Internet will try again, sending a new NTLM type3 request with a proper body.
See 
L<http://lists.samba.org/archive/jcifs/2006-September/006554.html>
for more details about this issue.

=head1 AUTHOR

Laurent Dami, C<< <la_____.da__@etat.ge.ch> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-apache2-authenntlm-cookie at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache2-AuthenNTLM-Cookie>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Apache2::AuthenNTLM::Cookie

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Apache2-AuthenNTLM-Cookie>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Apache2-AuthenNTLM-Cookie>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-AuthenNTLM-Cookie>

=item * Search CPAN

L<http://search.cpan.org/dist/Apache2-AuthenNTLM-Cookie>

=back


=head1 TESTING NOTE

This module has no tests ... because I didn't manage to write 
command-line tests that would successfully load the APR dynamic
libraries. Any hints welcome! Nevertheless, the module
has been successfully tested on Apache2.2/modperl2/solaris.


=head1 COPYRIGHT & LICENSE

Copyright 2008,2010 Laurent Dami, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


