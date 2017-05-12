use Test::More tests => 21;

use Data::Pipeline::Adapter::Array;
use Data::Pipeline::Iterator;
use Data::Pipeline::Iterator::Source;

use Data::Pipeline::Types qw( IteratorSource Iterator Adapter );

my $source = Data::Pipeline::Adapter::Array -> new(
    array => [ 1 .. 10 ]
);

ok( is_Adapter( $source ), "we have an adapter source" );

ok( is_IteratorSource( to_IteratorSource( $source ) ), "we can change it into an iterator source" );

ok( is_Iterator( to_Iterator( to_IteratorSource( $source ) ) ), "and then to an iterator" );

ok( is_Iterator( to_Iterator( $source ) ), "iterator from adapter" );

my $it1 = Data::Pipeline::Iterator -> new(
     source => $source # -> source
);

my $it2 = Data::Pipeline::Iterator -> new(
     source => $source # -> source
);

my $d = $source -> transform(
    Data::Pipeline::Iterator -> new( source => $source -> source )
);

is($it1 -> next, 1);
is($it1 -> next, 2);
is($it1 -> next, 3);
is($it1 -> next, 4);

is($it2 -> next, 1);
is($it2 -> next, 2);
is($it2 -> next, 3);
is($it2 -> next, 4);

is($it1 -> next, 5);
is($it1 -> next, 6);
is($it1 -> next, 7);
is($it1 -> next, 8);
is($it1 -> next, 9);
is($it1 -> next, 10);

ok( $it1 -> finished );

ok( !$it2 -> finished );

##
## can adapter write out to an array
##

my $array = [ ];

$d -> to( $array );

is_deeply( $array, [ 1 .. 10 ] );
