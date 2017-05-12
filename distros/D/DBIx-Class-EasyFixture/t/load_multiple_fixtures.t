use Test::Most;
use lib 't/lib';
use Sample::Schema;
use My::Fixtures;

my $schema = Sample::Schema->test_schema;

subtest 'load multiple fixtures' => sub {
    my $fixtures = My::Fixtures->new( schema => $schema );

    ok $fixtures->load( 'person_without_customer', 'person_with_customer' ),
      'We should be able to load a basic fixture';

    ok my $person
      = $schema->resultset('Person')
      ->find( { email => 'person@customer.com' } ),
      'We should be able to find our fixture object';
    is $person->name, 'sally', '... and their name should be correct';
    is $person->birthday->ymd, '1983-02-12', '... as should their birthday';
    ok $person->is_customer, '... and they should be a customer';

    ok my $person_without_customer
      = $schema->resultset('Person')->find( { email => 'not@home.com' } ),
      'We should be able to load more than one fixture';
    ok !$person_without_customer->is_customer,
      '... and have them work as expected';
};

subtest 'load multiple fixtures in a different order' => sub {
    my $fixtures = My::Fixtures->new( schema => $schema );

    ok $fixtures->load( 'person_with_customer', 'person_without_customer' ),
      'We should be able to load a basic fixture';

    ok my $person
      = $schema->resultset('Person')
      ->find( { email => 'person@customer.com' } ),
      'We should be able to find our fixture object';
    is $person->name, 'sally', '... and their name should be correct';
    is $person->birthday->ymd, '1983-02-12', '... as should their birthday';
    ok $person->is_customer, '... and they should be a customer';

    ok my $person_without_customer
      = $schema->resultset('Person')->find( { email => 'not@home.com' } ),
      'We should be able to load more than one fixture';
    ok !$person_without_customer->is_customer,
      '... and have them work as expected';
};

subtest 'load all fixtures' => sub {
    my $fixtures = My::Fixtures->new( schema => $schema );

    # note: just because this works in this test doesn't mean it will work for
    # your code. It's possible to create all sorts of scenarios where your
    # fixtures might have circular dependences, or maybe multiple fixtures
    # will try to violate a unique constraint.
    lives_ok { $fixtures->load( $fixtures->all_fixture_names ) }
    'Loading all validly constructed fixtures should suceed';
};

done_testing;
