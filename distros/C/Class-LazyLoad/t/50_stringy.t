use strict;

use lib 't/lib';

use Test::More tests => 6;

my ($CLASS, $TEST);
BEGIN {
    $CLASS = 'Class::LazyLoad';
    $TEST = 'Test5';

    use_ok( 'Test5' );
}

my $obj1 = $TEST->new();

isa_ok( $obj1, $TEST );
is( ref($obj1), $CLASS, "... but it's really a $CLASS" );

is( "$obj1", 42, 'stringification should convert the object' );

isa_ok( $obj1, $TEST );
is( ref($obj1), $TEST, "... and it's really a $TEST" );
