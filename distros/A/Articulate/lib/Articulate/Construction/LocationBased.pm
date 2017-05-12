package Articulate::Construction::LocationBased;
use strict;
use warnings;

=head1 NAME

Articulate::Construction::LocationBased - Create an item based on its
location

=head1 ATTRIBUTES

=head3 types

This should be a hashref mapping types to class names to be used in
constructors, where a type in this case is the penultimate endpoint of
locations with an even number of parts

So:

  article: Articulate::Item::Article

...would result in C</article/foo> or C<zone/public/article/foo>
becoming C<Articulate::Item::Article>s but not C<article>,
C<zone/article>, or C<zone/public/article>.

=head1 METHODS

=head3 construct

  $self->construct( {
    location => 'zone/public/article/hello-world',
    meta     => { ... }
    content  => " ... "
  } );

Attempts to construct the item. Determines the desired class based on
the mapping in the C<types> attribute, then calls C<<
$class->new($args) >> on the class. Returns C<undef> if no appropriate
class found.

In the above example, C<< $self->types->{article} >> would be
consulted.

If the location is root or not a multiple of 2 (e.g. C<zone/public> is
even and a C<zone> but C<zone/public/article> is odd), returns
C<undef>.

=cut

use Moo;

use Articulate::Syntax;

use Module::Load ();

has types => (
  is      => 'rw',
  default => sub { {} },
);

sub construct {
  my $self     = shift;
  my $args     = shift;
  my $location = new_location( $args->{location} );
  if ( scalar(@$location) and 0 == ( scalar(@$location) % 2 ) ) {
    if ( exists $self->types->{ $location->[-2] } ) {
      my $class = $self->types->{ $location->[-2] };
      Module::Load::load($class);
      return $class->new($args);
    }
  }
  return undef;
}

1;
