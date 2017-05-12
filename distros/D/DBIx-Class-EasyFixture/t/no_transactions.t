use Test::Most
  'bail';    # we bail because if this fails, everthing else will fail
use lib 't/lib';
use Sample::Schema;
use My::Fixtures;
use Capture::Tiny 'capture';

my $schema = Sample::Schema->test_schema;
my $fixtures = My::Fixtures->new( schema => $schema, no_transactions => 1 );
ok $fixtures->load('person_without_customer'),
  '... we should be able to load a basic fixture';
ok $fixtures->fixture_loaded('person_without_customer'),
  '... and then the fixture should be reported as loaded';

ok my $person
  = $schema->resultset('Person')->find( { email => 'not@home.com' } ),
  'We should be able to find our fixture object';
is $person->name, 'Bob', '... and their name should be correct';
is $person->birthday->ymd, '1983-02-12', '... as should their birthday';
ok !$person->is_customer, '... and they should not be a customer';

ok $fixtures->unload, 'We can call unload even if we have no transactions';
ok my $person2
  = $schema->resultset('Person')->find( { email => 'not@home.com' } ),
  '... but we should still be able to load the person';
ok $person2->delete, '... but we can delete the fixtures manually';
ok !$schema->resultset('Person')->find( { email => 'not@home.com' } ),
  '... and they should not be in the database';

done_testing;
