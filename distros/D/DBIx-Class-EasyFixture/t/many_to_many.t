use Test::Most;
use lib 't/lib';
use Sample::Schema;
use My::Fixtures;

my $schema = Sample::Schema->test_schema;

subtest 'loading order first' => sub {
    my $fixtures = My::Fixtures->new( schema => $schema );
    ok $fixtures->load('order_with_items'),
      'We should be able to load an order with items';

    ok my $order = $fixtures->get_result('order_with_items'),
      'We should be able to fetch our order';
    is $order->order_items->count, 2,
      '... and it should have two order items on it';
};

subtest 'loading order item first' => sub {
    my $fixtures = My::Fixtures->new( schema => $schema );
    ok $fixtures->load('order_item_hammer'),
      'We should be able to load an order with items';

    ok my $order = $fixtures->get_result('order_with_items'),
      'We should be able to fetch our order';
    is $order->order_items->count, 2,
      '... and it should have two order items on it';
};

done_testing;
