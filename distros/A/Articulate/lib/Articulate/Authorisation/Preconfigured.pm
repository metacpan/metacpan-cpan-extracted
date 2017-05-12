package Articulate::Authorisation::Preconfigured;
use strict;
use warnings;

use Moo;
use Articulate::Syntax qw( new_location_specification );

=head1 NAME

Articulate::Authorisation::Preconfigured - allow access to users in
your config

=cut

=head1 CONFIGURATION

Put this in your config:

  components:
    authorisation:
      Articulate::Authorisation:
        rules:
          - class: Articulate::Authorisation::Preconfigured
            rules:
              zone/public:
                "[guest]":
                  read: 1
                admin: 1

=head1 ATTRIBUTES

=head3 rules

The rules used to determine whether or not requests are authorised.
Defaults to C<{}>.

=cut

has rules => (
  is      => 'rw',
  default => sub { {} }
);

=head1 METHODS

=head3 new

No surprises here.

=head3 permitted

Goes through each of the locations in 'rules' (in ascending order of
length) and if the location in the permission request begins with that
rule, then look at the contents.

We then expect a hash of user ids, or C<[guest]> for users not logged
in. Their values should be 0 (for deny), 1 (for grant), or a hash of
verbs to grant/deny.

This is preconfigured access, so fine for a small personal or static
site, but if you have open sign-up or changing requirements then you
will probably find changing the config file and reloading the app gets
tedious after a while.

=cut

sub permitted {
  my $self       = shift;
  my $permission = shift;
  my $user_id    = $permission->user_id;
  my $location   = $permission->location;
  my $verb       = $permission->verb;
  my $rules      = $self->rules;
  my $access     = undef;

  foreach my $rule_location ( sort { $#$a <=> $#$b }
    map { new_location_specification $_ } keys %$rules )
  {
    if ( $rule_location->matches_ancestor_of($location) ) {
      if ( grep { $_ eq $user_id } keys %{ $rules->{$rule_location} } ) {
        if ( ref $rules->{$rule_location}->{$user_id} ) {
          if ( exists $rules->{$rule_location}->{$user_id}->{$verb} ) {
            my $value = !!$rules->{$rule_location}->{$user_id}->{$verb};
            return $permission->deny("User cannot $verb $rule_location")
              unless $value;
            $access = "User can $verb $rule_location";
          }
        }
        else {
          my $value = !!$rules->{$rule_location}->{$user_id};
          return $permission->deny("User cannot access $rule_location at all")
            unless $value;
          $access = "User can access $rule_location";
        }
      }
    }
  }
  if ( defined $access ) {
    return $permission->grant($access);
  }

  return $permission;
}

1;
