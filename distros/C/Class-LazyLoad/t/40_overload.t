use strict;

use lib 't/lib';

use Test::More tests => 11;

my ($CLASS, $TEST);
BEGIN {
    $CLASS = 'Class::LazyLoad';
    $TEST = 'Test4';

    use_ok( 'Test4' );
}

my $obj1 = $TEST->new();

isa_ok( $obj1, $TEST );
is( ref($obj1), $CLASS, "... but it's really a $CLASS" );

is( $obj1 + 54, 42 );

isa_ok( $obj1, $TEST );
is( ref($obj1), $TEST, "... and it's really a $TEST" );

my $obj2 = $TEST->new();

isa_ok( $obj2, $TEST );
is( ref($obj2), $CLASS, "... but it's really a $CLASS" );

like( "$obj2", qr/^Class::LazyLoad=ARRAY.*/, 'Stringification leaves object alone' );

isa_ok( $obj2, $TEST );
is( ref($obj2), $CLASS, "... and it's still a $CLASS" );
