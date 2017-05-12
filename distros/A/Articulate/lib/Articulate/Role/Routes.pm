package Articulate::Role::Routes;
use strict;
use warnings;
use Moo::Role;

=head1 NAME

Articulate::Role::Routes - allow routes to be enabled

=cut

=head1 DESCRIPTION

This is a helper role for route classes which works in tandem with L<Articulate::Syntax::Routes> (which allows a declarative style of routing).

Note that it is not mandatory to use either of these, you can use your frameworks's own routing capabiity and merely use Articulate for the service. If you do this, you will need to handle serialisation of L<Articulate::Response> objects yourself.

=head1 ATTRIBUTE

=head3 enabled

Do not set this directly, use C<enable>.

=cut

=head1 METHOD

=head3 enable

Finds all that were declared in that package. Note that this does B<not> respect inheritance by searching parent classes, roles, etc. for routes declared there: B<only> routes defined in the package to which this role is applied will be enabled.

=cut

sub enable { #ideally we want this to be able to switch on and off the routes.
  my $self   = shift;
  my $class  = ref $self;
  my $routes = "${class}::__routes";
  {
    no strict 'refs';
    $$routes //= [];
    $_->($self) for @$$routes;
  }
  $self->enabled(1);
}

has enabled => (
  is      => 'rw',
  default => sub { 0 },
);

with 'Articulate::Role::Component';

1;
