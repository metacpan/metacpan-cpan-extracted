use strict; use warnings;

use Test::More tests => 5;

use overload '""' => sub { __PACKAGE__ };
use Class::Observable;
our @ISA = 'Class::Observable';

__PACKAGE__->add_observer( 'Foo' );

my $self = bless {};

$self->add_observer( 'Bar' );

is( __PACKAGE__->count_observers, 1,
	'collisions between class and instance invocants are prevented' );

is( $self->count_observers, 2,
	'... and their observers properly coexist' );

is( $self->delete_observer( 'Bar' ), 0,
	'... and can be deleted' );

is( $self->count_observers, 1,
	'... without stepping on each other\'s toes' );

is( __PACKAGE__->count_observers, 1,
	'... from either perspective' );
