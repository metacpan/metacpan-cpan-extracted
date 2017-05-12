use strict;
use warnings; 
use Test::More qw( no_plan );

use_ok( 'CQL::Relation' );

my $relation = CQL::Relation->new( 'exact' );
isa_ok( $relation, 'CQL::Relation' );

$relation->addModifier( 'stem' );
is( $relation->toCQL(), 'exact/stem', 'toCQL()' );

is_deeply( [ $relation->getModifiers() ], [ [ undef, 'stem' ] ], 
    'getModifiers()' );
