use v5.15.3;
use strict;
use warnings;

BEGIN {
    use Data::AnyXfer;
    Data::AnyXfer->test(1);
}

use Test::Most;
use Test::LeakTrace;

use Data::AnyXfer::Elastic::Indices;
use Data::AnyXfer::Elastic::Index;
use DateTime ();

my $name = 'circular_ref_' . DateTime->now->ymd;

# Note that BLOCK is called more than once. This is because BLOCK might prepare caches which are not memory leaks.

no_leaks_ok {

# creates a new index, adds a document and then deletes it. Uses multiple elasticsearch objects.

    my $id1 = Data::AnyXfer::Elastic::Indices->new(
        silo         => 'public_data',
        connect_hint => 'readwrite',
    );

    $id1->get_aliases;
    eval { $id1->delete( index => $name ) };
    $id1->create( index => $name );
    $id1->get_mapping( index => $name );

    my $index = Data::AnyXfer::Elastic::Index->new(
        silo         => 'public_data',
        index_name   => $name,
        index_type   => 'tester',
        connect_hint => 'readwrite',
    );

    $index->index( body => { name => 'test document' } );

    my $id2 = Data::AnyXfer::Elastic::Indices->new(
        silo         => 'public_data',
        connect_hint => 'readwrite',
    );

    $id1->get_aliases;
    $id2->exists( index => $name );
    $id2->delete( index => $name );

    sleep(1);    # allow es update for second execution
}
'no leaks found';

done_testing;
