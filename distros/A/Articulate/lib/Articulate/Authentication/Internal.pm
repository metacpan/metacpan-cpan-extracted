package Articulate::Authentication::Internal;
use strict;
use warnings;

use Moo;

use Digest::SHA;
use Time::HiRes; # overrides time()

=head1 NAME

Articulate::Authentication::Internal

=cut

=head1 METHODS

=cut

=head3 authenticate

  $self->authenticate( $credentials );

Accepts and returns the credentials if the C<password> matches the C<user_id>. Always returns the credentials passed in.

=cut

has extra_salt => (
  is      => 'rw',
  default => "If you haven't already, try powdered vegetable bouillon"
);

sub authenticate {
  my $self        = shift;
  my $credentials = shift;
  my $user_id     = $credentials->fields->{user_id} // return;
  my $password    = $credentials->fields->{password} // return;

  if ( $self->verify_password( $user_id, $password ) ) {
    return $credentials->accept('Passwords match');
  }

  # if we ever need to know if the user does not exist, now is the time to ask,
  # but we do not externally expose the difference between
  # "user not found" and "password doesn't match"
  return $credentials;
}

sub _password_salt_and_hash {
  my $self = shift;
  return Digest::SHA::sha512_base64(
    $_[0] . $_[1] #:5.10 doesn't like shift . shift
  );
}

sub _generate_salt {

  # pseudorandom salt
  my $self = shift;
  return Digest::SHA::sha512_base64(
    time . (
      $self->extra_salt # don't allow the admin not to set a salt:
    )
  );
}

=head3 verify_password

  $self->verify_password( $user_id, $password );

Hashes the password provided with the user's salt and checks to see if the string matches the encrypted password in the user's meta.

Returns the result of C<eq>.

=cut

sub verify_password {
  my ( $self, $user_id, $plaintext_password ) = @_;

  my $user_meta               = $self->storage->get_meta("/users/$user_id");
  my $real_encrypted_password = $user_meta->{encrypted_password};
  my $salt                    = $user_meta->{salt};

  return undef
    unless defined $real_encrypted_password and defined $plaintext_password;

  return ( $real_encrypted_password eq
      $self->_password_salt_and_hash( $plaintext_password, $salt ) );
}

=head3 set_password

  $self->set_password( $user_id, $password );

Creates a new pseudorandom salt and uses it to hash the password provided.

Amends the C<encrypted_password> and C<salt> fields of the user's meta.

=cut

# note: currently this implicitly creates a user. Should set/patch create new content, or just edit it?
# maybe a create verb - but is is this going to be compatible with kvp stores? How will this work when you have content and meta and settings all to be created?
sub set_password {
  my ( $self, $user_id, $plaintext_password ) = @_;
  return undef
    unless $plaintext_password; # as empty passwords will only cause trouble.
  my $new_salt = $self->_generate_salt;
  $self->storage->patch_meta(
    "/user/$user_id",
    {
      encrypted_password =>
        $self->_password_salt_and_hash( $plaintext_password, $new_salt ),
      salt => $new_salt
    }
  );
}

=head3 create_user

  $self->create_user( $user_id, $password );

Creates a new user and sets the  C<encrypted_password> and C<salt> fields of the user's meta.

=cut

sub create_user {
  my ( $self, $user_id, $plaintext_password ) = @_;
  $self->storage->create("/user/$user_id");
  $self->storage->set_password( $user_id, $plaintext_password );
}

1;
