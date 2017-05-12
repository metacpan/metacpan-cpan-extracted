package Dallycot::AST::LibraryFunction;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Call function in an extension library

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

sub to_string {
  my ($self) = @_;

  my ( $parsing_library, $fname, $bindings, $options ) = @$self;

  return join( ",",
    "call($parsing_library#$fname",
    ( map { $_->to_string } @$bindings ),
    ( map { $_ . "->" . $options->{$_}->to_string } keys %$options ) )
    . ")";
}

sub execute {
  my ( $self, $engine ) = @_;

  my ( $parsing_library, $fname, $bindings, $options ) = @$self;

  return $parsing_library->instance->call_function( $fname, $engine, $options, @{$bindings} );
}

sub child_nodes {
  my ($self) = @_;

  return ( @{ $self->[2] }, values %{ $self->[3] } );
}

1;
