use Test::More tests => 12;

use Data::Pipeline::Iterator;
use Data::Pipeline qw(Pipeline Truncate Count Array );
use Data::Pipeline::Types qw( Iterator );

my $source = Array( array => [ 1 .. 10 ] );

my $iterator = Data::Pipeline::Iterator -> new(
    source => $source
);

my $pipeline = Pipeline(
    Truncate( length => 5 ),
    Count( name => 'c' )
);

my $action = $pipeline -> transform($iterator);
my $action2 = $pipeline -> transform($source);
my $action3 = $pipeline -> transform([ 1 .. 10 ]);

my $p2 = Pipeline( );

isa_ok( $p2, 'Data::Pipeline::Aggregator::Pipeline' );

my $array2 = to_Iterator( [ 1 .. 10 ] );

isa_ok( $array2, 'Data::Pipeline::Iterator' );

my $action4 = $p2 -> transform([ 1 .. 10 ]);
isa_ok( $action4, 'Data::Pipeline::Iterator' );

# equivalent to:
# $action = Data::Pipeline::Count -> new -> transform(
#    Data::Pipeline::Truncate -> new( length => 5 ) -> transform(
#        $iterator
#    )
# );

ok( !$action -> finished );
is( $action -> next -> {'c'}, 5 );
ok( $action -> finished );

ok( !$action2 -> finished );
is( $action2 -> next -> {'c'}, 5 );
ok( $action2 -> finished );

ok( !$action3 -> finished );
is( $action3 -> next -> {'c'}, 5 );
ok( $action3 -> finished );
