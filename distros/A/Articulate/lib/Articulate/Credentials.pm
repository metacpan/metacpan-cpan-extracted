package Articulate::Credentials;
use strict;
use warnings;

use Moo;
use overload bool => sub { shift->accepted }, '0+' => sub { shift->rejected };

=head1 NAME

Articulate::Credentials - represent an authentication request/response

=cut

=head1 FUNCTIONS

=head3 new_credentials

  my $credentials = new_credentials $user_id, $password;
  my $credentials = new_credentials { email => $email, api_key => $key };

Creates a new request, using the user_id and password supplied as the
respective arguments; or other fields if they are supplied instead.

=cut

use Exporter::Declare;
default_exports qw(new_credentials);

sub new_credentials {
  return shift if ref $_[0] eq __PACKAGE__;
  __PACKAGE__->new(
    {
      fields => (
        ( ref $_[0] eq ref {} )
        ? $_[0]
        : {
          user_id  => shift,
          password => shift,
        }
      ),
    }
  );
}

=head1 METHODS

=head3 new

An unremarkable Moo constructor.

=cut

=head3 accept

  $credentials->accept('Password matched');

Declares that the credentials are valid, for the reason given; sets
C<accpeted> and C<rejected> and populates the stack trace.

=cut

sub accept {
  my $self   = shift;
  my $reason = shift;

  # die if granted or denied are already set?
  $self->accepted(1);
  $self->reason($reason);
  $self->stack_trace( Devel::StackTrace->new );
  return $self;
}

=head3 reject

  $credentials->reject('User not found');

Declares that the credentials are invalid, for the reason given; sets
C<accpeted> and C<rejected> and populates the stack trace.

=cut

sub reject {
  my $self   = shift;
  my $reason = shift;

  # die if granted or denied are already set?
  $self->accepted(0);
  $self->rejected(1);
  $self->reason($reason);
  $self->stack_trace( Devel::StackTrace->new );
  return $self;
}

=head1 ATTRIBUTES

=head3 fields

The credentials provided, typically user_id and password.

=cut

has fields => (
  is      => 'rw',
  default => sub { {} },
);

=head3 accepted

Whether or not the credentials have been explicitly accepted. The value
of this is used for overload behaviour.

Please do not explicitly set this. Use C<accept> instead.

=cut

has accepted => (
  is      => 'rw',
  default => sub { 0 },
);

=head3 rejected

Whether the credentials have been explicitly rejected.

Please do not explicitly set this. Use C<reject> instead.

=cut

has rejected => (
  is      => 'rw',
  default => sub { 0 },
);

=head3 reason

The reason for the acceptance or rejection of credentials.

Please do not explicitly set this. Use C<accept> or C<reject> instead.

=cut

has reason => (
  is      => 'rw',
  default => sub { '' },
);

=head3 stack_trace

The stack trace at the point of acceptance or rejection of credentials.

Please do not explicitly set this. Use C<accept> or C<reject> instead.

=cut

has stack_trace => (
  is      => 'rw',
  default => sub { '' },
);

=head1 SEE ALSO

=over

=item * L<Articulate::Authentication>

=item * L<Articulate::Permission> (which performs a similar function for L<Articulate::Authorisation>)

=back

=cut

1;
