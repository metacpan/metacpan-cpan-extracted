use strict; use warnings;

use Test::More tests => 15;

{
	package Something;
	use Class::Observable;
	our @ISA = qw( Class::Observable );
	sub new { bless {}, shift }
}

ok( Something->add_observer( 'Foo' ),  'Add observer to class ...' );
is( Something->count_observers, 1, '... and check that it\'s there' );

my $omething = Something->new;
ok( $omething->add_observer( 'Bar' ),  'Add observer to instance' );
is( $omething->count_observers, 2, '... and check that the instance sees both observers' );
is( $omething->count_observers - ( ref $omething )->count_observers, 1, '... separately from each other' );

my $omeotherthing = Something->new;
ok( $omething->copy_observers( $omeotherthing ), 'Copy observers from one instance to the other' );
is( $omeotherthing->count_observers, 3, '... and check that the number of total observers on that instance is correct' );

is( $omething->delete_all_observers, 1, 'Delete object-level observers' );
is( $omething->count_observers - ( ref $omething )->count_observers, 0, '... and check that they\'re gone' );
is( $omething->count_observers, 1, '... but the instance still sees the class-level observer' );

ok( !Something->delete_observer( 'Foo' ), 'Delete class-level observer' );
is( $omething->count_observers, 0, '... and check that the first instance sees no observers anymore' );
is( $omeotherthing->count_observers, 2, '... but the second one retains its instance copy of the class-level observer' );

ok( $omeotherthing->delete_all_observers, 'Delete instance observers on second instance...' );
is( $omeotherthing->count_observers, 0, '... and now it must not have any anymore' );
