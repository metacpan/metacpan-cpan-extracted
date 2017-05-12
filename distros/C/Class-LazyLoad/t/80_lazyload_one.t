use strict;

use lib 't/lib';

use Test::More tests => 9;

my ($CLASS, $TEST);
BEGIN {
    $CLASS = 'Class::LazyLoad';
    $TEST = 'Test2';

    use_ok( $CLASS . '::Functions', qw( lazyload_one ) );
    use_ok( $TEST );
}

my $obj1 = $TEST->new;
isa_ok( $obj1, $TEST );
is( ref($obj1), $TEST, "... and it's really a $TEST" );

my $lazy = lazyload_one( $TEST );
isa_ok( $lazy, $TEST );
is( ref($lazy), $CLASS, "... but it's really a $CLASS" );

ok( $lazy->hello, 'Function call successful' );

isa_ok( $lazy, $TEST );
is( ref($lazy), $TEST, "... and it's really a $TEST" );
