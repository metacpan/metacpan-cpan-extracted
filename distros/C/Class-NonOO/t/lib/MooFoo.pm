package MooFoo;

use Moo;
use Class::NonOO;

has bar => ( is => 'rw', default => sub { 1 } );

sub baz {
  my ($self) = @_;
  $self->bar + 1;
}

sub boop {
  my ($self) = @_;
  return ( $self->bar, $self->baz );
}

as_function
  export => [qw/ bar baz boop /],
  args => [ bar => 5 ];

1;
