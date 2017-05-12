
use Test::More tests => 28;

use_ok('DataFlow::Item');

my $item = DataFlow::Item->new;
ok($item);

# initial tests
is_deeply( $item->metadata, {}, 'metadata is empty' );
is_deeply( $item->channels, {}, 'channels is empty' );

# metadata tests
is( $item->set_metadata( 'testem', 123 ), $item, 'sets and returns $self' );
is( $item->get_metadata('testem'), 123, 'gets the right metadata' );
is_deeply( $item->metakeys, ['testem'] );

is( $item->set_metadata( 'testem1', 'aaa' ), $item, 'sets and returns $self' );
is_deeply(
    $item->metadata,
    {
        'testem'  => 123,
        'testem1' => 'aaa',
    }
);

# regular data tests
is( $item->set_data( 'teste', 456 ), $item, 'sets and returns $self' );
is( $item->get_data('teste'), 456, 'gets the right data' );
is_deeply( $item->channel_list, ['teste'] );

is( $item->set_data( 'teste1', 567 ), $item, 'sets and returns $self' );
is( $item->set_data( 'teste2', 678 ), $item, 'sets and returns $self' );
is_deeply(
    $item->channels,
    {
        'teste'  => 456,
        'teste1' => 567,
        'teste2' => 678,
    }
);
is( scalar( grep { $_ eq 'teste' } @{ $item->channel_list } ),  1 );
is( scalar( grep { $_ eq 'teste1' } @{ $item->channel_list } ), 1 );
is( scalar( grep { $_ eq 'teste2' } @{ $item->channel_list } ), 1 );

# tests on narrow()
my $narrow = $item->narrow('teste1');
isa_ok( $narrow, 'DataFlow::Item' );
is_deeply( $narrow->channels, { 'teste1' => 567, } );
is_deeply( $narrow->metadata, $item->metadata );

# tests on clone()
my $clone = $item->clone('teste1');
isa_ok( $clone, 'DataFlow::Item' );
is_deeply( $clone->channels, $item->channels );
is_deeply( $clone->metadata, $item->metadata );

# tests on itemize
my $ized = DataFlow::Item->itemize( 'teste1' => 567 );
isa_ok( $ized, 'DataFlow::Item' );
is_deeply( $ized->channel_list, ['teste1'] );
is_deeply( $ized->channels, { 'teste1' => 567, } );
is_deeply( $ized->metadata, {}, 'metadata is empty' );

