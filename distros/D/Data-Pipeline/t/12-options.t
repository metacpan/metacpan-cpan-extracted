use Test::More tests => 11;

use Data::Pipeline qw( Pipeline Count Array );

use Data::Pipeline::Iterator::Options;
use Data::Pipeline::Iterator::ArrayOptions;


###
# only constants
###

my $it = Data::Pipeline::Iterator::Options -> new(
    params => {
        foo => 1,
        bar => '59',
        baz => 'abcs'
    }
);

isa_ok( $it, 'Data::Pipeline::Iterator::Options' );

ok( !$it -> finished );

my $c = $it -> next;

is_deeply( $c, { foo => 1, bar => '59', baz => 'abcs' } );

ok( $it -> finished );

###
# now with a single iterator
###

$it = Data::Pipeline::Iterator::Options -> new(
    params => {
        foo => Array( array => [ 1, 2, 3, 4 ] ),
        bar => '59',
        baz => 'abcs'
    }
);

isa_ok( $it, 'Data::Pipeline::Iterator::Options' );

is( Count() -> transform( $it ) -> next -> {count}, 4 );

$it = Data::Pipeline::Iterator::Options -> new(
    params => {
        foo => Array( array => [ 1, 2, 3, 4 ] ),
        bar => Array( array => [ qw(a b c d e f) ] ),
        baz => 'abcs'
    }
);

isa_ok( $it, 'Data::Pipeline::Iterator::Options' );

is( Count() -> transform( $it ) -> next -> {count}, 24 );

$it = Data::Pipeline::Iterator::ArrayOptions -> new(
    params => [ 1, '59', 'abcs' ]
);

ok( !$it -> finished );

$c = $it -> next;

is_deeply( $c, [ 1, '59', 'abcs' ] );

ok( $it -> finished );

