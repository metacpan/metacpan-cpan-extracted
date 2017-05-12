package AxKit::App::TABOO::AddXSLParams::Session;
use 5.6.0;
use strict;
use warnings;
use AxKit;
use AxKit::App::TABOO;
use Session;
use Apache::Constants;
use Apache::Cookie;
use Apache::Request;
use Apache::URI;
use AxKit::App::TABOO;

our $VERSION = '0.1';

sub handler {
  my $r = shift;
  my $uri = $r->uri;
  my $cgi = Apache::Request->instance($r);
  
  my $session = AxKit::App::TABOO::session($r);
  if (defined($session)) {
    $cgi->parms->set('session.id' => $session->session_id);
    $cgi->parms->set('session.authlevel' => AxKit::App::TABOO::authlevel($session));    
    $cgi->parms->set('session.loggedin' => AxKit::App::TABOO::loggedin($session));
  } else {
    $cgi->parms->set('session.authlevel' => '0');
    $cgi->parms->set('session.loggedin' => 'guest');
  }
  return OK;
}

1;
__END__

=head1 NAME

AxKit::App::TABOO::AddXSLParams::Session - Minimal session parameter XSLT access for TABOO

=head1 SYNOPSIS

  # in httpd.conf or .htaccess
  AxAddPlugin AxKit::App::TABOO::AddXSLParams::Session

=head1 DESCRIPTION

AxKit::App::TABOO::AddXSLParams::Session provides a way to pass the
critical session info to XSLT params.

Like A:A:P:A:Request, you can access session values by defining a
specially named XSL parameter. These three are available, and can be
used as the final example indicates:

  <xsl:param name="session.id"/>
  <xsl:param name="session.authlevel"/>
  <xsl:param name="session.loggedin"/>

  ...
  <xsl:value-of select="$session.loggedin"/>

These parameters can supply the session ID, the authorisation level
and the username of the logged in user. If there is no logged in user,
the latter will return C<0> and C<guest> respectively.


=head1 SEE ALSO

L<Apache::AxKit::Plugin::AddXSLParams::Request>

=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut
