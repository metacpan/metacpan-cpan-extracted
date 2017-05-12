use Test::Most;
use lib 't/lib';
use Sample::Schema;
use My::Fixtures;

my $schema = Sample::Schema->test_schema;
my $fixtures = My::Fixtures->new( schema => $schema );

ok !$fixtures->fixture_loaded('person_without_customer'),
  'Fixtures we have not loaded should be reported as not loaded';
ok !$fixtures->fixture_loaded('person_with_customer'),
  'Fixtures we have not loaded should be reported as not loaded';

ok $fixtures->load('all_people'), '... we should be able to load groups';

ok $fixtures->fixture_loaded('person_without_customer'),
  '... and then the fixture should be reported as loaded';
ok $fixtures->fixture_loaded('person_with_customer'),
  '... and then the fixture should be reported as loaded';

ok my $person
  = $schema->resultset('Person')->find( { email => 'not@home.com' } ),
  'We should be able to find our fixture object';
is $person->name, 'Bob', '... and their name should be correct';
is $person->birthday->ymd, '1983-02-12', '... as should their birthday';
ok !$person->is_customer, '... and they should not be a customer';

ok my $person_with_customer
  = $schema->resultset('Person')->find( { email => 'person@customer.com' } ),
  '... and we should be able find our person with customer';
ok $person_with_customer->is_customer, '... and they should be a customer';

done_testing;
