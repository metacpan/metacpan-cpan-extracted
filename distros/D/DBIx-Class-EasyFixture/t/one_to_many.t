
use Test::Most;
use lib 't/lib';
use Sample::Schema;
use My::Fixtures;

my $schema = Sample::Schema->test_schema;

{
    # introduce a scope to test DEMOLISH
    ok my $fixtures = My::Fixtures->new( schema => $schema ),
      'Creating a fixtures object should succeed';
    isa_ok $fixtures, 'My::Fixtures';
    isa_ok $fixtures, 'DBIx::Class::EasyFixture';

    ok $fixtures->load('order_without_items', 'second_order_without_items'),
      'We should be able to load a basic fixture';

    ok my $person
      = $schema->resultset('Person')
      ->find( { email => 'person@customer.com' } ),
      'We should be able to find our fixture object';
    is $person->name, 'sally', '... and their name should be correct';
    is $person->birthday->ymd, '1983-02-12', '... as should their birthday';
    ok $person->is_customer, '... and they should be a customer';

    is $person->customer->orders->count, 2,
        '... and the customer should have two orders';
}

done_testing;
