# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author: rmp
#
package ClearPress::authenticator::db;
use strict;
use warnings;
use base qw(ClearPress::authenticator Class::Accessor);
use Readonly;
use Carp;
use English qw(-no_match_vars);

our $VERSION = q[477.1.2];

__PACKAGE__->mk_accessors(qw(dbh));

our $SUPPORTED_CIPHERS = {
			  mysql   => sub { my ($self, $str) = @_; $self->dyn_use('Crypt::MySQL'); return Crypt::MySQL::password($str); },
			  mysql41 => sub { my ($self, $str) = @_; $self->dyn_use('Crypt::MySQL'); return Crypt::MySQL::password41($str); },
			  sha1    => sub { my ($self, $str) = @_; $self->dyn_use('Digest::SHA');  return Digest::SHA::sha1_hex($str); },
			  sha128  => sub { my ($self, $str) = @_; $self->dyn_use('Digest::SHA');  return Digest::SHA::sha128_hex($str); },
			  sha256  => sub { my ($self, $str) = @_; $self->dyn_use('Digest::SHA');  return Digest::SHA::sha256_hex($str); },
			  sha384  => sub { my ($self, $str) = @_; $self->dyn_use('Digest::SHA');  return Digest::SHA::sha384_hex($str); },
			  sha512  => sub { my ($self, $str) = @_; $self->dyn_use('Digest::SHA');  return Digest::SHA::sha512_hex($str); },
			  md5     => sub { my ($self, $str) = @_; $self->dyn_use('Digest::MD5');  return Digest::MD5::md5_hex($str); },
			 };
Readonly::Scalar our $DEFAULT_TABLE          => 'user';
Readonly::Scalar our $DEFAULT_USERNAME_FIELD => 'username';
Readonly::Scalar our $DEFAULT_PASSWORD_FIELD => 'pass';
Readonly::Scalar our $DEFAULT_CIPHER         => 'sha1';

sub table {
  my ($self, $v) = @_;

  if($v) {
    $self->{table} = $v;
  }

  if($self->{table}) {
    return $self->{table};
  }

  return $DEFAULT_TABLE;
}

sub username_field {
  my ($self, $v) = @_;

  if($v) {
    $self->{username_field} = $v;
  }

  if($self->{username_field}) {
    return $self->{username_field};
  }

  return $DEFAULT_USERNAME_FIELD;
}

sub password_field {
  my ($self, $v) = @_;

  if($v) {
    $self->{password_field} = $v;
  }

  if($self->{password_field}) {
    return $self->{password_field};
  }

  return $DEFAULT_PASSWORD_FIELD;
}

sub cipher {
  my ($self, $v) = @_;

  if($v) {
    $self->{cipher} = $v;
  }

  if($self->{cipher}) {
    return $self->{cipher};
  }

  return $DEFAULT_CIPHER;
}

sub authen_credentials {
  my ($self, $ref) = @_;

  if(!$ref ||
     !$ref->{username} ||
     !$ref->{password} ) {
    return;
  }

  my $dbh     = $self->dbh();
  my $table   = $self->table;
  my $user_f  = $self->username_field;
  my $pass_f  = $self->password_field;
  my $c_type  = $self->cipher;
  my $cipher  = $SUPPORTED_CIPHERS->{$c_type};

  if(!$cipher) {
    croak qq[Unsupported cipher: $c_type];
  }

  my $digest  = $cipher->($self, $ref->{password});
  my $query   = qq[SELECT $user_f FROM $table WHERE $user_f=? AND $pass_f=?];
  my $results = $dbh->selectall_arrayref($query, {}, $ref->{username}, $digest);

  if(!scalar @{$results}) {
    return;
  }

  return $ref;
}

1;
__END__

=head1 NAME

ClearPress::authenticator::db

=head1 VERSION

$LastChangedRevision: 470 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 table - get/set accessor for database table to use

  $oDBAuth->table('user');
  my $sTable = $oDBAuth->table();

=head2 username_field - get/set accessor for field containing username

  $oDBAuth->username_field('username');
  my $sUsernameField = $oDBAuth->username_field();

=head2 password_field - get/set accessor for field containing password

  $oDBAuth->password_field('pass');
  my $sPasswordField = $oDBAuth->password_field();

=head2 cipher - get/set accessor for encryption function name

  $oDBAuth->cipher('sha1');
  my $sCipher = $oDBAuth->cipher();

=head2 dbh - get/set accessor for database handle to use for query

  $oDBAuth->dbh($oDBH);
  my $oDBH = $oDBAuth->dbh();

=head2 authen_credentials - attempt to authenticate against database using given username & password

  my $hrAuthenticated = $oDBAuth->authen_credentials({username => $sUsername, password => $sPassword});

  returns undef or hashref

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item base

=item ClearPress::authenticator

=item Readonly

=item Carp

=item English

=item Class::Accessor

=back

=head1 OPTIONAL DEPENDENCIES

You will probably need one of the following

=over

=item Crypt::MySQL

for mysql and mysql41 support

=item Digest::SHA

for sha1, sha128, sha256, sha384, sha512 support

=item Digest::MD5

for md5 support

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
