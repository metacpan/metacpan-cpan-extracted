package AxKit::XSP::BasicAuth;

use Apache;
use Apache::AxKit::Language::XSP::TaglibHelper;
use Apache::Session;
use Date::Format;

use base qw(Apache::AxKit::Language::XSP::TaglibHelper);

sub parse_start {
  my ($e, $tag, %attribs) = @_;

  if($tag eq 'login') {
    $e->start_expr($tag);
    return q{
    my $args = Apache::Request->instance($r)->parms;
    my $value;
  while (($_, $value) = each %$args) {
    $Apache::AxKit::Plugin::BasicSession::session{$_} = $value
      if m{credential_(\d+)};
  }
  $r->headers_in->unset('Content-Length');
  return $r->prev->uri if ($r->prev);}
  } elsif($tag eq 'logout') {
    $e->start_expr($tag);
    return q{$r->auth_type->logout($r, \%Apache::AxKit::Plugin::BasicSession::session)}
  } elsif($tag eq 'is-logged-in') {
    $e->start_expr($tag);
    return q{defined
      $Apache::AxKit::Plugin::BasicSession::session{credential_0}
        && $Apache::AxKit::Plugin::BasicSession::session{credential_0} ne ''}
  } elsif($tag eq 'get-username') {
    $e->start_expr($tag);
    return q{$Apache::AxKit::Plugin::BasicSession::session{credential_0}};
  } else {
    return Apache::AxKit::Language::XSP::TaglibHelper::parse_start(@_);
  }
}

sub parse_end {
  my ($e, $tag, %attribs) = @_;

  if($tag eq 'login' || $tag eq 'logout' || $tag eq 'is-logged-in' || $tag eq 'get-username') {
    $e->end_expr;
    return '';
  } else {
    Apache::AxKit::Language::XSP::TaglibHelper::parse_end(@_);
  }
}

$NS = 'http://www.nichework.com/2003/XSP/BasicAuth';
$VERSION = "0.22";
@EXPORT_TAGS = qw( login() logout() get-username() is-logged-in() );

1;

__END__

=head1 NAME

AxKit::XSP::BasicAuth - Tag library for basic cookie-based authentication.

=head1 SYNOPSIS

Add the session: namespace to your XSP C<<xsp:page>> tag:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:auth="http://www.nichework.com/2003/XSP/BasicAuth"
         xmlns:session="http://www.axkit.org/2002/XSP/BasicSession">

And add this taglib to AxKit (via httpd.conf or .htaccess):

    SetHandler AxKit
    PerlModule Apache::AxKit::Plugin::BasicAuth

    <Location />
      AuthType Apache::AxKit::Plugin::BasicAuth
      AuthName BasicSession
    </Location>
    <Location /style>
      require valid-user
    </Location>

    # Session Management
    AxAddPlugin Apache::AxKit::Plugin::BasicSession
    PerlSetVar BasicSessionDataStore DB_File
    PerlSetVar BasicSessionArgs      "FileName => /tmp/session"

    AxAddPlugin Apache::AxKit::Plugin::BasicSession
    AxAddPlugin Apache::AxKit::Plugin::AddXSLParams::BasicSession

    # Authentication
    PerlSetVar BasicSessionLoginScript /login

=head1 DESCRIPTION

This taglib provides simple form-and-cookie based authentication using
Apache::Session and Apache::AuthCookie.

In the tag reference below, AuthNameToken designates the name given
for AuthName.

=head1 Tag Reference

=head2 C<E<lt>auth:loginE<gt>>

Attempt to log the user in.

Typically, the page you set in AuthNameTokenLoginScript is an XSP page
that uses a form built with PerForm to check the user.  After
verifying the identity of the user (e.g. in start_submit), you will
have use this tag tell BasicAuth that the user is authenticated and
that the username/password information should be stored in the
session.

In constructing your form, it is important to understand that
BasicAuth is expecting your username to be in a form field called
credential_0.  That is the only required form field name, but if other
fields are named in the credential_? format, the will be stored in the
session information as well.  This allows you to store the plaintext
user password in credential_1 if you need access to it (among other
things).

=head2 C<E<lt>auth:logoutE<gt>>

Log the user out.  This is done by removing any keys that match the
credential_\d+ regular expression from the session information.

=head2 C<E<lt>auth:get-usernameE<gt>>

Returns the username that was used to log in.

=head2 C<E<lt>auth:is-logged-inE<gt>>

Returns true if the page if the session contains a logged in user.

=head1 AUTHOR

Mark A. Hershberger, mah@everybody.org

=head1 COPYRIGHT

Copyright (c) 2003 Mark A. Hershberger. All rights reserved. This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

AxKit, Apache::Session, AxKit::XSP::Session, AxKit::XSP::BasicSession

Cocoon2 Session Taglib
(http://xml.apache.org/cocoon2/userdocs/xsp/session.html)

=cut
