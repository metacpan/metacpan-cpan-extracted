# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author: rmp
#
package ClearPress::authenticator::ldap;
use strict;
use warnings;
use base qw(ClearPress::authenticator);
use Readonly;
use Carp;
use Net::LDAP;

our $VERSION = q[476.1.1];

Readonly::Scalar our $DEFAULT_SERVER    => 'ldaps://ldap.local:636';
Readonly::Scalar our $DEFAULT_AD_DOMAIN => 'WORKGROUP';

sub server {
  my ($self, $srv) = @_;
  if($srv) {
    $self->{server} = $srv;
  }

  if($self->{server}) {
    return $self->{server};
  }

  return $DEFAULT_SERVER;
}

sub ad_domain {
  my ($self, $domain) = @_;
  if($domain) {
    $self->{ad_domain} = $domain;
  }

  if($self->{ad_domain}) {
    return $self->{ad_domain};
  }

  return $DEFAULT_AD_DOMAIN;
}

sub _ldap {
  my $self = shift;

  if(!$self->{_ldap}) {
    $self->{_ldap} = Net::LDAP->new($self->server);
  }

  return $self->{_ldap};
}

sub authen_credentials {
  my ($self, $ref) = @_;

  if(!$ref ||
     !$ref->{username} ||
     !$ref->{password} ) {
    return;
  }

  my $ldap = $self->_ldap;
  if(!$ldap) {
    croak qq[Failed to connect to @{[$self->server()]}. Is it available?];
  }
  my $ad_domain   = $self->ad_domain;
  my $fq_username = sprintf q[%s\%s], $ad_domain, $ref->{username};
  my $auth_msg    = $ldap->bind(
				$fq_username,
				'password' => $ref->{password},
			       );
  if($auth_msg->code) {
    carp $auth_msg->error;
    return;
  }

  return $ref;
}

1;
__END__

=head1 NAME

ClearPress::authenticator::ldap

=head1 VERSION

$LastChangedRevision: 470 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 server - server url (ldaps://ldap.local)

  my $sLDAPServer = $oLDAP->server();

=head2 ad_domain - Active Directory Domain (WORKGROUP)

  my $ad_domain = $oLDAP->ad_domain();

=head2 _ldap - Net::LDAP object

=head2 authen_credentials - attempt to authenticate against LDAP/AD using given username & password

  my $hrAuthenticated = $oLDAP->authen_credentials({username => $sUsername, password => $sPassword});

  returns undef or hashref

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item base

=item ClearPress::authenticator

=item Net::LDAP

=item Readonly

=item Carp

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
