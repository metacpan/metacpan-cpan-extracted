#!perl

use Data::Frame::Setup;

use PDL::Core qw(pdl);
use Test2::V0;

use Data::Frame::Indexer qw(:all);

subtest indexer_s => sub {
    is( indexer_s()->indexer->length, 0, 'indexer_s()' );
    is( indexer_s( [] )->indexer->length, 0, 'indexer_s([])' );
    is( indexer_s(undef), undef, 'indexer_s(undef)' );
    is( indexer_s( pdl( [ 1, 2 ] ) )->indexer, [ 1, 2 ], 'indexer_s($pdl)' );

    my $indexer = indexer_s( [qw(x y)] );
    isa_ok( $indexer, ['Data::Frame::Indexer::Label'] );
    is( $indexer->indexer, [qw(x y)], 'indexer_s([qw(x y)])' );
    is( indexer_i($indexer), $indexer, 'indexer_i($indexer)' );
};

subtest indexer_i => sub {
    is( indexer_i()->indexer->length, 0, 'indexer_i()' );
    is( indexer_i( [] )->indexer->length, 0, 'indexer_i([])' );
    is( indexer_i(undef), undef, 'indexer_i(undef)' );

    my $indexer = indexer_i( [ 1, 2 ] );
    isa_ok( $indexer, ['Data::Frame::Indexer::Integer'] );
    is( $indexer->indexer, [ 1, 2 ], 'indexer_s([1, 2])' );

    is( indexer_s($indexer), $indexer, 'indexer_s($indexer)' );
};

done_testing;
