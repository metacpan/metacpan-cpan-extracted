use Test::More tests => 6;

package My::Machine;
use Moose;
extends 'Data::Pipeline::Machine';
use Data::Pipeline::Machine;
use Data::Pipeline qw( Array Count CSV );

pipeline(
    bar =>
    Pipeline( foo => (
                   array => Option( 'array', default => [ 1 .. 4 ] ),
                   q => 2
               ) ),
    CSV( column_names => [qw( count )] )
);

pipeline(
    foo =>
    Array( array => Option( 'array', default => [ 1 .. 3 ] ) ),
    Count
);

pipeline(
    Pipeline( foo => (
        array => Option( 'array' )
    ) )
);

package main;

my $m = My::Machine -> new;

isa_ok( $m, 'My::Machine' );

my $result = 0;

isa_ok( $m, 'My::Machine' );

TODO: {
local $TODO = "Machines aren't returning good iterators yet";
my $i = $m -> from( array => [ 1 .. 5 ] );


ok( $i -> can('to'), 'Iterator has to() method' );

eval {
    $i -> to( \$result );
};

is( 0+$result, 5 );

eval {
    $m -> from( array => [ 1 .. 30 ] ) -> to( \$result );
};

is( 0+$result, 30 );

eval {
    $m -> from( ) -> to( \$result );
};

is( 0+$result, 3 );
};
