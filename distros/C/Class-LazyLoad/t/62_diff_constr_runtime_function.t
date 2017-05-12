use strict;

use lib 't/lib';

use Test::More tests => 20;

my ($CLASS, $TEST);
BEGIN {
    $CLASS = 'Class::LazyLoad';
    $TEST = 'Test7';

    use_ok( $TEST );
    use_ok( "${CLASS}::Functions", 'lazyload', 'unlazyload' );
}

my $obj1 = $TEST->my_new;

isa_ok( $obj1, $TEST );
is( ref($obj1), $TEST, "... and it's a $TEST" );

ok( defined $obj1->hello, "Calling a method still works" );

ok( lazyload( $TEST, 'my_new' ), 'lazyload() called' );

my $obj2 = $TEST->my_new;

isa_ok( $obj2, $TEST );
is( ref($obj2), $CLASS, "... but it's really a $CLASS" );

ok( defined $obj2->hello, "Calling a method still works and changes the object" );

isa_ok( $obj2, $TEST );
is( ref($obj2), $TEST, "... and it's really a $TEST" );

my $obj3 = $TEST->my_new();

isa_ok( $obj3, $TEST );
is( ref($obj3), $CLASS, "... but it's really a $CLASS" );

like( "$obj3", qr/^Class::LazyLoad=ARRAY.*/, 'Stringification leaves object alone' );

isa_ok( $obj3, $TEST );
is( ref($obj3), $CLASS, "... and it's still a $CLASS" );

ok( unlazyload( $TEST ), 'unlazyload() called' );

my $obj4 = $TEST->my_new;

isa_ok( $obj4, $TEST );
is( ref($obj4), $TEST, "... and it's a $TEST" );

ok( defined $obj4->hello, "Calling a method still works" );
