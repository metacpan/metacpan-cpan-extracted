use strict;

use lib 't/lib';

use Test::More tests => 13;

my ($CLASS, $TEST);
BEGIN {
    $CLASS = 'Class::LazyLoad';
    $TEST = 'Test2';

    use_ok( $CLASS . '::Functions', qw( lazyload unlazyload lazyload_one ) );
}

my $lazy = lazyload_one( $TEST, 'new' );

isa_ok( $lazy, $TEST );
is( ref($lazy), $CLASS, "... but it's really a $CLASS" );

ok( $lazy->hello, 'Function call successful' );

isa_ok( $lazy, $TEST );
is( ref($lazy), $TEST, "... and it's really a $TEST" );

my $lazy2 = lazyload_one( $TEST, '' );
isa_ok( $lazy2, $TEST );
is( ref($lazy2), $CLASS, "... but it's really a $CLASS" );

lazyload( $TEST );

my $obj1 = $TEST->new;
isa_ok( $lazy2, $TEST );
is( ref($lazy2), $CLASS, "... but it's really a $CLASS" );

unlazyload( $TEST );

ok( $lazy->hello, 'Function call successful after lazyload' );

isa_ok( $lazy, $TEST );
is( ref($lazy), $TEST, "... and it's really a $TEST" );
