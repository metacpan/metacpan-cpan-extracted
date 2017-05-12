package Articulate::Permission;
use strict;
use warnings;

use Moo;
use Devel::StackTrace;

use overload bool => sub { shift->granted }, '0+' => sub { shift->granted };

=head1 NAME

Articulate::Permission - represent a permission request/response

=cut

=head1 FUNCTIONS

=head3 new_permission

  my $permission = new_permission $user, verb => $location;

Creates a new permission request, using the user, verb and location
supplied as the respective arguments.

=cut

use Exporter::Declare;
default_exports qw(new_permission);

sub new_permission {
  __PACKAGE__->new(
    {
      user_id => shift // '[guest]',
      verb => shift,
      location => shift
    }
  );
}

=head1 METHODS

=head3 new

An unremarkable Moo constructor.

=cut

=head3 grant

  $permission->grant('Anybody can do that!');

Declares that the user has that permission, for the reason given; sets
C<granted> and C<denied> and populates the stack trace.

=cut

sub grant {
  my $self   = shift;
  my $reason = shift;

  # die if granted or denied are already set?
  $self->granted(1);
  $self->reason($reason);
  $self->stack_trace( Devel::StackTrace->new );
  return $self;
}

=head3 deny

  $permission->deny('Don\t touch that!');

Declares that the user does not have that permission, for the reason
given; sets C<granted> and C<denied> and populates the stack trace.

=cut

sub deny {
  my $self   = shift;
  my $reason = shift;

  # die if granted or denied are already set?
  $self->granted(0);
  $self->denied(1);
  $self->reason($reason);
  $self->stack_trace( Devel::StackTrace->new );
  return $self;
}

=head1 ATTRIBUTES

=head3 user_id

The user_id requesting permission to access the resource.

=cut

has user_id => (
  is      => 'rw',
  default => sub { undef },
);

=head3 verb

The action being performed, e.g. C<read>, C<write>, etc. The verbs
available are entirely dependant on the application.

A permission request will be granted or denied by an authorisation rule
(see Articulate::Authorisation), who will typically implement verbs
that bay be different from but are either a) broader than, or b)
equally broad as, the verbs used by the Articulate::Service.

=cut

has verb => (
  is      => 'rw',
  default => sub { 'error' },
);

=head3 location

The location of the resource for which permission is requested.

=cut

has location => (
  is      => 'rw',
  default => sub { [] },
);

=head3 granted

Whether or not the permission has been explicitly granted. The value of
this is used for overload behaviour.

Please do not explicitly set this. Use C<grant> instead.

=cut

has granted => (
  is      => 'rw',
  default => sub { 0 },
);

=head3 denied

Whether the permission has been explicitly denied.

Please do not explicitly set this. Use C<deny> instead.

=cut

has denied => (
  is      => 'rw',
  default => sub { 0 }
);

=head3 reason

The reason for the grant or denial of permission.

Please do not explicitly set this. Use C<grant> or C<deny> instead.

=cut

has reason => (
  is      => 'rw',
  default => sub { '' }
);

=head3 stack_trace

The stack trace at the point of grant or denial of permission.

Please do not explicitly set this. Use C<grant> or C<deny> instead.

=cut

has stack_trace => (
  is      => 'rw',
  default => sub { '' }
);

=head1 SEE ALSO

=over

=item * L<Articulate::Authorisation>

=item * L<Articulate::Credentials> (which performs a similar function for L<Articulate::Authentication>)

=back

=cut

1;
