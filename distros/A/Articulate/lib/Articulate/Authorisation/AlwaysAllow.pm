package Articulate::Authorisation::AlwaysAllow;
use strict;
use warnings;

use Moo;

=head1 NAME

Articulate::Authorisation::AlwaysAllow - don't use this in production

=cut

=head1 CONFIGURATION

Put this in your C<development.yml>, NOT in your C<config.yml> or your
C<production.yml>. You have been warned.

  components:
    authorisation:
      Articulate::Authorisation:
        rules:
          - Articulate::Authorisation::AlwaysAllow

There's nothing else to configure, the answer is always yes.

=head1 METHODS

=head3 new

Does what all good C<new> methods do, nothing more.

=head3 permitted

Handles all the complex business logic required to ensure that the
request is always authorised.

So don't use this in production.

=cut

sub permitted {
  my $self       = shift;
  my $permission = shift;
  $permission->grant('Anything is possible!');
}

=head1 BUGS

Don't come crying to me if you use this in production.

=cut

1;
