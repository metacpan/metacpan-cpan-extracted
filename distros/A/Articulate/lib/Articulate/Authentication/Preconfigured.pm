package Articulate::Authentication::Preconfigured;
use strict;
use warnings;

use Moo;

use Digest::SHA;
use Articulate::Storage;
use Time::HiRes; # overrides time()

=head1 NAME

Articulate::Authentication::Preconfigured - do not use this in production

=cut

=head1 WARNING

Warning: This is highly insecure, you will be storing your passwords in plain text in the configuration file.

It is suitable only for getting a project started, and should be promptly removed when a user account has been created which stores encrypted passwords somewhere.

=head1 CONFIGURATION

  authentication:
    Articulate::Authentication:
      providers:
        - class: Articulate::Authentication::Preconfigured
          args:
            passwords:
              username: insecure_password

=head1 ATTRIBUTES

=head3 passwords

A simple hash of keys and values where the user is the key and the password is the value.

=cut

has passwords => (
  is      => 'rw',
  default => sub { {} },
);

=head3 authenticate

  $self->authenticate( $credentials );

Accepts and returns the credentials if the C<password> matches the C<user_id>. Always returns the credentials passed in.

=cut

sub authenticate {
  my $self        = shift;
  my $credentials = shift;
  my $user_id     = $credentials->fields->{user_id} // return;
  my $password    = $credentials->fields->{password} // return;

  if ( exists $self->passwords->{$user_id} ) {
    return $credentials->accept('Passwords match')
      if $password eq $self->passwords->{$user_id};
  }

  # if we ever need to know if the user does not exist, now is the time to ask,
  # but we do not externally expose the difference between
  # "user not found" and "password doesn't match"
  return $credentials;
}

1;
