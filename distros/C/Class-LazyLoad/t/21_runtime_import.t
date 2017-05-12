use strict;

use lib 't/lib';

use Test::More tests => 19;

my ($CLASS, $TEST);
BEGIN {
    $CLASS = 'Class::LazyLoad';
    $TEST = 'Test2';

    use_ok( $CLASS, $TEST );
}

my $obj1 = $TEST->new;

isa_ok( $obj1, $TEST );
is( ref($obj1), $CLASS, "... but it's really a $CLASS" );

ok( defined $obj1->hello, "Calling a method works and changes the object" );

isa_ok( $obj1, $TEST );
is( ref($obj1), $TEST, "... and it's really a $TEST" );

my $obj2 = $TEST->new;
isa_ok( $obj2, $TEST );
is( ref($obj2), $CLASS, "... but it's really a $CLASS" );

can_ok( $obj2, 'hello' );

isa_ok( $obj2, $TEST );
is( ref($obj2), $CLASS, "... and it's still a $TEST (can_ok wraps lexically)" );

ok( $obj2->can( 'hello' ), 'Calling can() ourselves ...' );

isa_ok( $obj2, $TEST );
is( ref($obj2), $TEST, "... and it's now a $TEST" );

my $obj3 = $TEST->new();

isa_ok( $obj3, $TEST );
is( ref($obj3), $CLASS, "... but it's really a $CLASS" );

like( "$obj3", qr/^Class::LazyLoad=ARRAY.*/, 'Stringification leaves object alone' );

isa_ok( $obj3, $TEST );
is( ref($obj3), $CLASS, "... and it's still a $CLASS" );
