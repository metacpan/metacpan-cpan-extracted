use Test::Most;
use lib 't/lib';
use My::Objects;
use My::Fixtures;
use Sample::Schema;

my $schema = Sample::Schema->test_schema;

my $people_rs = $schema->resultset('Person');

my $fixtures = My::Fixtures->new( { schema => $schema } );
$fixtures->load('person_without_customer');
my $objects = My::Objects->new(
    {   schema      => $schema,
        object_base => 'My::Object::',
        debug       => 0,
    }
);
$objects->load_objects;

my $person_result = $fixtures->get_result('person_without_customer');
my $person = My::Object::Person->new( { result_source => $person_result, object_source => $objects } );

my @attributes = qw(person_id name birthday email);
foreach my $attribute (@attributes) {
    is $person->$attribute, $person_result->$attribute,
      "The '$attribute' attribute should be delegated correctly";
}
ok !$person->can('save'),
  '... but other dbic attributes should not be inherited';
ok $person->result_source->isa('Sample::Schema::Result::Person'),
  '... but we can get at them via our result_source()';

ok $person->can('is_customer'),
  'Our custom methods in the class should exist';
ok !$person->is_customer, '... and should return the correct response';

$fixtures->load('basic_customer');

my $customers = $objects->objectset('Customer');
is $customers->count, 1, 'We should only have one customer';
ok my $customer = $customers->first,
  '... and we should be able to fetch that customer';
ok $customer->isa('My::Object::Customer'),
  '... and it should be our object class';
ok $customer->isa('My::Object::Person'),
  '... and correctly inherit from person';
ok $customer->can('name'),
  '... and it should inherit the Person::name() method';
is $customer->name, $customer->person->name,
  '... and return the correct value';

$customer->name('completely new name');
$customer->update;
$customer = $objects->objectset('Customer')->first;

is $customer->name, 'completely new name',
  'Updating inherited attributes should work';

$person_result = $fixtures->get_result('person_with_customer');
$person = My::Object::Person->new( { result_source => $person_result, object_source => $objects } );

isa_ok $person->customer, 'My::Object::Customer';
ok $person->is_customer,  '... and our custom methods should still work';

$fixtures->unload;
$fixtures->load('order_with_items');

# we only have one order loaded
my $order       = $objects->objectset('Order')->first;
my $order_items = $order->order_items;
is $order_items->count, 2, 'Methods returning an objectset should work';

while ( my $order_item = $order_items->next ) {
    ok $order_item->isa('My::Object::OrderItem'),
      '... and individual results should have the right class';
}

done_testing;
