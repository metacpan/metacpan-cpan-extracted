package AxKit::App::TABOO::Handler::Login;

# This is a simple mod_perl Handler to implement session tracking,
# just for the purpose of login users in.

use Apache::Constants qw(:common);
use Apache;
use Apache::Request;
#use Apache::Cookie;
use Session;
use AxKit::App::TABOO::Data::User::Contributor;
use AxKit::App::TABOO;
use strict;
use warnings;
use Carp;


our $VERSION = '0.2';

sub handler {
  my $r = shift;

  my %session_config = AxKit::App::TABOO::session_config($r);

  my $cookie = $r->header_in('Cookie');
  if (defined($cookie) && $cookie =~ m/VID=(\w*)/) {
    # so, the user is logged in allready. Kill that session, then
    my $session = new Session $1, %session_config;
    $session->delete if defined $session;
  }
  my $outtext = '<html><head>';
  my $req = Apache::Request->instance($r);
  my $user = AxKit::App::TABOO::Data::User::Contributor->new();
  my $authlevel = $user->load_authlevel($req->param('username'));
  if ($authlevel) { # So, the user exists
    my $encrypted = $user->load_passwd($req->param('username'));
    if ($req->param('clear') && $encrypted && (crypt($req->param('clear'),$encrypted) eq $encrypted)) {
      my $redirect = $r->header_in("Referer") || '/';
      my $session = new Session undef, %session_config;
      $r->header_out("Set-Cookie" => 'VID='.$session->session_id());
      $session->set(authlevel => $authlevel);
      $session->set(loggedin => $req->param('username'));
      $outtext .= '<meta http-equiv="refresh" content="1;url='.$redirect.'">';
      $outtext .= '<title>Log in</title></head><body><h1>Logged in</h1><p>Password is valid, go to <a href="/">main page</a>.</p>';
    } else {
      $outtext .= '<title>Log in</title></head><body><h1>Log in</h1><p>Password is invalid, go back and try again!</p>';
    }
  } else {
    $outtext .= '<title>Log in</title></head><body><h1>Log in</h1><p>Username was not found, go back and try again!</p>';
  }
  $r->send_http_header('text/html');
  $r->print($outtext."\n</body></html>\n");
  return OK;
}

1;
__END__

=head1 NAME

AxKit::App::TABOO::Handler::Login - Straight mod_perl handler to authenticate a user in TABOO

=head1 SYNOPSIS

  # in httpd.conf
    PerlModule AxKit::App::TABOO::Handler::Login
  <Location /login>
     SetHandler perl-script
     PerlHandler AxKit::App::TABOO::Handler::Login
     PerlSendHeader On
  </Location>

  PerlSetVar TABOODataStore DB_File
  PerlSetVar TABOOArgs      "FileName => /tmp/taboodemo-session"


=head1 DESCRIPTION

This is a straight mod_perl handler to do the authentication in
TABOO. It has come into being after having struggled with
L<Apache::AxKit::Plugin::Session> and L<AxKit::XSP::BasicSession> and
will simply give the user a cookie if the password matches, and set
the username and the authorisation level in the session. Not my
preferred way of doing things, but it shall have to do for now.

The session datastore uses L<Session> and can be configured like that
module, see the above example.

=head1 TODO

This does something as atrocious as returning a HTML document
directly. I tried returning something to transform with XSLT, but will
have to find a better solution. I tried with an AxKit Provider too,
but that segfaulted on me.

I'd really like to get L<Apache::AxKit::Plugin::Session> going.

=head1 SEE ALSO

L<AxKit::App::TABOO::AddXSLParams::Session>

=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut
