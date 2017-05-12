package Articulate::Authorisation::OwnerOverride;
use strict;
use warnings;

use Moo;

=head1 NAME

Articulate::Authorisation::OwnerOverride - always say yes to the owner

=cut

=head1 CONFIGURATION

Put this in your config:

  components:
    authorisation:
      Articulate::Authorisation:
       rules:
          - Articulate::Authorisation::OwnerOverride

Or, if you want the owner   components:     authorisation:      
Articulate::Authorisation:         rules:           - class:
Articulate::Authorisation::OwnerOverride             args:             
 owner: administrator

=head1 ATTRIBUTES

=head3 owner

The username of the owner. Defaults to C<owner>.

=cut

has owner => (
  is      => 'rw',
  default => sub { 'owner' }
);

=head1 METHODS

=head3 new

Yep, C<new> works just as you'd expect.

=head3 permitted

Grants any request if the user asking is the owner. By default this is
the user called C<owner>, but it could be someone else, if the C<owner>
attribute is set.

=cut

sub permitted {
  my $self       = shift;
  my $permission = shift;
  $permission->grant('Site owner can do anything')
    if ( ( $permission->user_id // '' ) eq $self->owner );
  return $permission;
}

1;
