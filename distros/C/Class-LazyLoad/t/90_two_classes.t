use strict;

use lib 't/lib';

use Test::More tests => 10;

my ($CLASS, $TEST1, $TEST2);
BEGIN {
    $CLASS = 'Class::LazyLoad';
    $TEST1 = 'Test1';
    $TEST2 = 'Test2';

    use_ok( $TEST1 );
    use_ok( $CLASS . '::Functions', qw( lazyload ) );
}

my $obj1 = $TEST1->new;
isa_ok( $obj1, $TEST1 );
is( ref($obj1), $CLASS, "... and it's really a $CLASS" );

lazyload( $TEST2 );

my $obj2 = $TEST2->new;
isa_ok( $obj2, $TEST2 );
is( ref($obj2), $CLASS, "... and it's really a $CLASS" );

$obj1->hello;

isa_ok( $obj1, $TEST1 );
is( ref($obj1), $TEST1, "... and it's really a $TEST1" );

$obj2->hello;

isa_ok( $obj2, $TEST2 );
is( ref($obj2), $TEST2, "... and it's really a $TEST2" );
