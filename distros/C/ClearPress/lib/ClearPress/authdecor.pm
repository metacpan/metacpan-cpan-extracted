# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author: rmp
#
package ClearPress::authdecor;
use strict;
use warnings;
use base qw(ClearPress::decorator Exporter);
use ClearPress::authenticator::session;
use Readonly;

our $VERSION = q[477.1.4];

Readonly::Scalar our $DOMAIN      => 'mysite.com';
Readonly::Scalar our $AUTH_COOKIE => 'mysite_sso';
Readonly::Array  our @EXPORT_OK   => qw($AUTH_COOKIE);

sub new {
  my ($class, @args) = @_;
  my $self = $class->SUPER::new(@args);

  $self->{title}       = 'My Site';
  $self->{stylesheet}  = [qw(/css/mysite.css)];
  $self->{meta_author} = q$Author: zerojinx $;

  if(!ref $self->{jsfile}) {
    $self->{jsfile} = [];
  }

  unshift @{$self->{jsfile}}, qw(/js/jquery-1.3.2.min.js);

  return $self;
}

sub username {
  my ($self, $username) = @_;

  if(defined $username) {
    $self->{username} = $username;
  }

  if(defined $self->{username}) {
    return $self->{username};
  }

  my $auth   = ClearPress::authenticator::session->new();
  my $cgi    = $self->cgi();
  my $cookie = $cgi->cookie($AUTH_COOKIE);

  if(!$cookie) {
    #########
    # no auth cookie. don't bother trying to decrypt
    #
    return;
  }

  my $ref = $auth->authen_token($cookie);
  if(!$ref) {
    #########
    # Failed to authenticate session token
    #
    return;
  }

  return $ref->{username};
}

sub linkbucket {
  my $self = shift;

  my $authenticated = $self->username()?1:0;

  #########
  # un/authenticated stuff
  #
  my $defaults = [
		  $authenticated ? {'Logout' => '/logout'} : {'Login' => '/login'},
		 ];

  #########
  # standard links
  #
  my $standard = [
		  {'Home' => q[/]},
		 ];
  #########
  # session-based (user-defined) links
  #
  my $session = [];

  return [@{$defaults},
	  @{$standard},
	  @{$session}];
}

sub site_header {
  my ($self, @args) = @_;

  my $header = $self->SUPER::site_header(@args);
  $header   .= q[<div><a id="homelink" href="/"><img src="/gfx/blank.gif" alt="" title="Home"/></a></div><div><ul id="siteactions">];
  my $links  = $self->linkbucket();

  for my $link (@{$links}) {
    my ($k, $v) = each %{$link};
    my $onclick = q[];

    if($v =~ /[ ]/smx) {
      #########
      # $v includes ajax onclick
      #
      ($v, $onclick) = split /\s+/smx, $v, 2;
      $onclick = qq[ onclick="$onclick"];
    }

    my $id   = 'act_'.lc $k;
    $id      =~ s/[^[:lower:]]/_/smxg;
    $header .= qq[<li><a id="$id" href="$v"$onclick>$k</a></li>];
  }

  $header .= <<"EOT";
</ul><br style="clear:both"/></div><!--end siteactions-->
<div id="d_login_cntr">@{[$self->site_login_form]}</div><!--end d_login_cntr-->
EOT

  return $header.q[<div id="main">];
}

sub footer {
  return q[</div><!--end main--></body></html>];
}

sub site_login_form {
  my $host = $ENV{HTTP_X_FORWARDED_HOST} || $ENV{HTTP_HOST} || q[];

  if($host) {
    $host = "https://$host";
  }

  return <<"EOT";
<form class="login_form" method="post" action="$host/login">
 <dl class="tbl">
  <dt><label for="cred_0">Username</label></dt>
  <dd><input type="text" size="14" name="cred_0" id="cred_0"/></dd>
  <dt><label for="cred_1">Password</label></dt>
  <dd><input type="password" size="14" name="cred_1" id="cred_1"/></dd>
 </dl>
 <p class="buttons"><input type="submit" value="Log in"/></p>
</form>
EOT
}

1;
__END__

=head1 NAME

ClearPress::authdecor

=head1 VERSION

$Revision: 470 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new - constructor, overridden from superclass but calls up. Present here to set default page attributes like title, stylesheet etc.

  my $oDecor = ClearPress::decor->new();

=head2 username - overridden from superclass - fetch username of authenticated user from LDAP or session

  my $sUsername = $oDecor->username();

=head2 linkbucket - data structure containing default links. TODO: examine user session

  my $arLinkHash = $oDecor->linkbucket();

  Structure is:
  [
    { Name => href },
    { Name => href },
    { Name => href },
    { Name => href },
  ]

=head2 site_header - overridden from superclass. Tacks the linkbucket on to the default header

  my $sSiteHeaderHTML = $oDecor->site_header();

=head2 footer - overridden from superclass. Closes div#main

  my $sSiteFooterHTML = $oDecor->footer();

=head2 site_login_form - authentication form used for popup and cgi-bin/login

  my $sSiteLoginHTML = $oDecor->site_login_form();

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item Readonly

=item ClearPress::authenticator::session

=item ClearPress::decorator

=item Exporter

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
