# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author: rmp
#
package ClearPress::authenticator::session;
use strict;
use warnings;
use Crypt::CBC;
use base qw(ClearPress::authenticator);
use Readonly;
use Carp;
use MIME::Base64 qw(encode_base64 decode_base64);
use YAML::Tiny qw(Load Dump);

our $VERSION = q[477.1.2];

Readonly::Scalar our $KEY => q[topsecretkey];

sub authen_token {
  my ($self, $token) = @_;

  return $self->decode_token($token);
}

sub encode_token {
  my ($self, $user_hash) = @_;

  my $user_yaml = Dump($user_hash);
  my $encrypted = $self->cipher->encrypt($user_yaml);
  my $encoded   = encode_base64($encrypted);

  return $encoded;
}

sub decode_token {
  my ($self, $token) = @_;

  my $decoded = q[];
  eval {
    $decoded = decode_base64($token);
  } or do {
    carp q[Failed to decode token];
    return;
  };

  my $decrypted = q[];
  eval {
    $decrypted = $self->cipher->decrypt($decoded);
  } or do {
    carp q[Failed to decrypt token];
    return;
  };

  my $deyamled;
  eval {
    $deyamled = Load($decrypted);

  } or do {
    carp q[Failed to de-YAML token];
    return;
  };

  return $deyamled;
}

sub key {
  my ($self, $key) = @_;

  if($key) {
    $self->{key} = $key;
  }

  if($self->{key}) {
    return $self->{key};
  }

  return $KEY;
}

sub cipher {
  my $self = shift;

  if(!$self->{cipher}) {
    $self->{cipher} = Crypt::CBC->new(
				      -cipher => 'Blowfish',
				      -key    => $self->key,
				     );
  }

  return $self->{cipher};
}

1;
__END__

=head1 NAME

ClearPress::authenticator::session

=head1 VERSION

$LastChangedRevision: 470 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 authen_token - validate a token, usually from cookie

  my @aResults = $oSession->authen_token($sToken);

=head2 encode_token - encrypt and base64 encode user information

  my $sEncoded = $oSession->encode_token($hrUserData);

=head2 decode_token - decode and decrypt a token

  my $hrUserData = $oSession->decode_token($sEncoded);

=head2 key - get/set accessor for cipher key (optionally configured during construction)

  my $sKey = $oSession->key();

=head2 cipher - a configure Crypt::CBC object

  my $oCipher = $oSession->cipher();

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item Crypt::CBC

=item base

=item ClearPress::authenticator

=item Readonly

=item Carp

=item MIME::Base64

=item YAML::Syck

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
