package Catalyst::Plugin::Widget::Base;

=head1 NAME

Catalyst::Plugin::Widget::Base - Base class for all kind of widgets

=cut

use Carp qw( croak );
use Moose;

use overload
	'""' => 'render',
	bool => sub { ref shift },
;


=head1 CONSTRUCTOR

=head2 new ( $context, %attributes )

Create widget instance with current Catalyst context.
First and required argument for all Catalyst::Plugin::Widget::Base subclasses
must be a Catalyst context (usually $c in your controller).

=cut

around BUILDARGS => sub {
	my ( $orig,$class,$context ) = splice @_,0,3;

	+{ context => $context, %{ $class->$orig( @_ ) } };
};


=head1 METHODS

=head2 context

Returns current Catalyst application context.

=cut

has context => ( is => 'ro', isa => 'Catalyst', required => 1 );


=head2 render

Render widget to string (must be overriden in subclasses).
This method called implicitly during widget stringification,
so you can do something like:

  $c->res->body( "<html>$widget</html> )

=cut

sub render {
	croak 'Not implemented: ' . ref(shift) .'::render';
}


__PACKAGE__->meta->make_immutable;

1;

