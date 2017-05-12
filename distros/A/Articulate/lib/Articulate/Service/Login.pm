package Articulate::Service::Login;

use strict;
use warnings;

use Articulate::Syntax;

use Moo;
with 'Articulate::Role::Service';

use Try::Tiny;
use Scalar::Util qw(blessed);

=head1 NAME

Articulate::Service::Login - provide login, logout

=cut

=head1 METHODS

=head1 handle_login

  $self->handle_login( {user_id => 'admin', password => 'secret!' } )

Tries to authenticate a user and, if successful, sets a session var
(see L<Articulate::FrameworkAdapter>).

Returns C<< {user_id => $user_id } >> if successful, throws an error
otherwise.

=head1 handle_logout

  $self->handle_login( {user_id => 'admin', password => 'secret!' } )

Destroys the current session.

Returns C<< {user_id => $user_id } >>.

=cut

sub handle_login {
  my $self    = shift;
  my $request = shift;

  my $user_id  = $request->data->{user_id};
  my $password = $request->data->{password};

  if ( defined $user_id ) {
    if ( $self->authentication->login( $user_id, $password ) ) {
      $self->framework->user_id($user_id);
      return new_response success => { user_id => $user_id };
    } # Can we handle all the exceptions with 403s?
    else {
      throw_error Forbidden => 'Incorrect credentials';
    }
  }
  else {
    # todo: see if we have email and try to identify a user and verify with that
    throw_error Forbidden => 'Missing user id';
  }

}

sub handle_logout {
  my $self    = shift;
  my $request = shift;
  my $user_id = $self->framework->user_id;
  $self->framework->session->destroy();
  return new_response success => { user_id => $user_id };
}

1;
