package Articulate::Authentication;
use strict;
use warnings;

use Moo;
with 'Articulate::Role::Component';

use Articulate::Syntax qw(new_credentials instantiate_array);

=head1 NAME

Articulate::Authentication - determine if a user who they claim to be

=head1 SYNOPSIS

  # in config:
  components:
    authentication:
      Articulate::Authentication:
        providers:
          - Articulate::Authentication::AlwaysAllow

  # then any component can dp
  $component->authentication->login($credentials);
  $component->authentication->login($user_id, $password);

=head1 ATTRIBUTE

=head3 providers

A list of providers which can respond to C<login>.

=cut

has providers => (
  is      => 'rw',
  default => sub { [] },
  coerce  => sub { instantiate_array(@_) },
);

=head3 login

  $authentication->login($credentials);
  $authentication->login( $user_id, $password );

Asks each provider if the credentials supplied match a known user.
Credentials may be in whatever form will satisfy the C<credentials>
function in L<Articulate::Credentials> (username and password, hashref
or credentials object).

Each provider must respond true, false, or undef. A true value means
the user is authenticated. A false value means that the user exists but
is explicitly refused access (this should only be used in exceptional
circumstances) and an undef value means the user cannot be
authenticated by the provider (but could be authenticated by some other
provider).

=cut

sub login {
  my $self        = shift;
  my $credentials = new_credentials @_;
  foreach my $provider ( @{ $self->providers } ) {
    return $credentials if $provider->authenticate($credentials);
    return $credentials if $credentials->rejected;
  }
  return $credentials->deny('No provider authenticated these credentials');
}

=head3 create_user

  $authentication->create_user( $user_id, $password );

Requests that a new user is created. Each provider must respond true,
false, or undef.

=cut

sub create_user {
  my $self     = shift;
  my $user_id  = shift;
  my $password = shift;
  foreach my $provider ( @{ $self->providers } ) {
    if ( defined( $provider->create_user( $user_id, $password ) ) ) {
      return ($user_id);
    }
  }
  return (undef);
}

=head1 SEE ALSO

=over

=item * L<Articulate::Authorisation>

=item * L<Articulate::Credentials>

=back

=cut

1;
