use Test::More tests => 6;

use Data::Pipeline::Types qw( Iterator IteratorSource Adapter );

use Data::Pipeline::Iterator;
use Data::Pipeline::Iterator::Source;

ok(
    is_IteratorSource(
        Data::Pipeline::Iterator::Source -> new(
            has_next => sub { 0 },
            get_next => sub { }
        )
    )
);

ok( 
    is_Iterator( 
        Data::Pipeline::Iterator -> new( 
            source => Data::Pipeline::Iterator::Source -> new(
                has_next => sub { 0 },
                get_next => sub { }
             ) 
        ) 
    ) 
);

isa_ok( to_Adapter( [ 1 .. 10 ] ), 'Data::Pipeline::Adapter::Array' );
isa_ok( to_IteratorSource( [ 1 .. 10 ] ), 'Data::Pipeline::Iterator::Source' );
isa_ok( to_Iterator( to_IteratorSource( [ 1 .. 10 ] ) ), 'Data::Pipeline::Iterator' );

isa_ok( to_Iterator( 'foo' ), 'Data::Pipeline::Iterator' );
