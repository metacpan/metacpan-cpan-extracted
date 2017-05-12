use strict;
use Test::More;
use strict;
use warnings;

use Test::More;
use Test::Fatal qw(lives_ok exception);
use Test::Mock::Guard;
use ArangoDB;
use JSON;

if ( !$ENV{TEST_ARANGODB_PORT} ) {
    plan skip_all => 'Can"t find port of arangod';
}

my $port   = $ENV{TEST_ARANGODB_PORT};
my $config = {
    host => 'localhost',
    port => $port,
};

init();

sub init {
    my $db = ArangoDB->new($config);
    map { $_->drop } @{ $db->collections };
}

subtest 'create edge' => sub {
    my $db    = ArangoDB->new($config);
    my $coll  = $db->create('foo');
    my $doc1  = $coll->save( { foo => 'bar', baz => 10 } );
    my $doc2  = $coll->save( { foo => 'qux', baz => 11 } );
    my $edge1 = $coll->save_edge( $doc1, $doc2, { foo => 1 } );
    is $edge1->from, $doc1->document_handle;
    is $edge1->to,   $doc2->document_handle;
    my $edge2 = $db->edge($edge1);
    is_deeply( $edge1, $edge2 );

    my $edge3 = $coll->save_edge( $doc1, $doc2 );
    is_deeply $edge3->content, {};

    like exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_post => sub {die}
            }
        );
        $coll->save_edge( $doc2, $doc1 );
    }, qr/Failed to save the new edge to the collection/;

};

subtest 'get edges' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('test1');
    my $doc1 = $coll->save( { foo => 1 } );
    my $doc2 = $coll->save( { foo => 2 } );
    my $doc3 = $coll->save( { foo => 3 } );
    my $doc4 = $coll->save( { foo => 4 } );

    my $e1 = $coll->save_edge( $doc1, $doc2, { e => 1 } );
    $coll->save_edge( $doc1, $doc3, { e => 2 } );
    $coll->save_edge( $doc2, $doc1, { e => 4 } );
    $coll->save_edge( $doc3, $doc1, { e => 4 } );

    my $e1_1 = $db->edge($e1);
    is_deeply $e1_1, $e1;
    like exception { $db->edge() }, qr/^Failed to get the edge/;

    my $edges = $doc1->any_edges();
    ok !grep { !$_->isa('ArangoDB::Edge') } @$edges;
    is scalar @$edges, 4;

    $edges = $doc2->any_edges();
    is scalar @$edges, 2;

    $edges = $doc4->any_edges();
    is scalar @$edges, 0;

    my $e = exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_get => sub {die}
            }
        );
        $doc2->any_edges();
    };
    like $e, qr{Failed to get edges\(.+?\) that related to the document};

    $edges = $doc1->out_edges();
    is scalar @$edges, 2;

    $edges = $doc4->out_edges();
    is scalar @$edges, 0;

    #in edges
    $edges = $doc1->in_edges();
    is scalar @$edges, 2;

    $edges = $doc2->in_edges();
    is scalar @$edges, 1;

    $edges = $doc4->in_edges();
    is scalar @$edges, 0;
};

subtest 'Update edge' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->find('test1');
    my $doc  = $coll->first_example( { foo => 3 } );
    my $edge = $doc->in_edges($doc)->[0];
    $edge->set( e => '2-2' );
    $edge->save();
    my $new_edge = $db->edge($edge);
    is_deeply $new_edge->content, { e => '2-2' };

    like exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_put => sub {die}
            }
        );
        $edge->save();
    }, qr/^Failed to update the edge/;

};

subtest 'delete edges' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->find('test1');
    my $doc  = $coll->first_example( { foo => 3 } );

    my $edges = $doc->out_edges();

    lives_ok {
        for my $edge (@$edges) {
            $edge->delete();
        }
    };

    like exception {
        $edges->[0]->delete();
    }, qr/^Failed to delete the edge/;

};

done_testing;
