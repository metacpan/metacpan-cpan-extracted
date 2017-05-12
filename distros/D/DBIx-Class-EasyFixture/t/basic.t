use Test::Most;
use lib 't/lib';
use Sample::Schema;
use My::Fixtures;
use Capture::Tiny 'capture';
use Carp::Always;

my $schema = Sample::Schema->test_schema;
ok my $fixtures = My::Fixtures->new( schema => $schema ),
  'Creating a fixtures object should succeed';
isa_ok $fixtures, 'My::Fixtures';
isa_ok $fixtures, 'DBIx::Class::EasyFixture';

ok !$fixtures->fixture_loaded('person_without_customer'),
  'Fixtures we have not loaded should be reported as not loaded';
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

ok $fixtures->unload, 'We should be able to unload our fixtures';

ok !$schema->resultset('Person')->find( { email => 'not@home.com' } ),
  '... and we should no longer find our fixtures';

subtest 'fetching key result' => sub {
    my ( undef, $stderr, @results ) = capture {
        $fixtures->get_result('person_without_customer');
    };
    like $stderr,
      qr/Fixture 'person_without_customer' was never loaded/,
      'Fetching a key result for an unloaded fixture should warn';
    ok !@results, '... and not return anything';

    ok $fixtures->load('person_without_customer'),
      'We should be able to load a basic fixture';

    ok my $person = $fixtures->get_result('person_without_customer'),
      'get_result() should return the primary result object for a fixture';
    is $person->name, 'Bob', '... and their name should be correct';
    is $person->birthday->ymd, '1983-02-12', '... as should their birthday';
    ok !$person->is_customer, '... and they should not be a customer';

    ok $fixtures->unload, 'We should be able to unload our fixtures';

    ok !$schema->resultset('Person')->find( { email => 'not@home.com' } ),
      '... and we should no longer find our fixtures';
};

subtest 'inline attributes' => sub {
    my @customers = $fixtures->load(qw/
        customer_inline_require_hashref
        customer_inline_require_arrayref
        customer_inline_require_scalar
    /);
    
    is $customers[0]->person->email, 'person2@customer.com',
        'Fixtures defined with inline hashrefs should work';
    is $customers[1]->person->email, 'person3@customer.com',
        'Fixtures defined with inline arrayrefs should work';
    is $customers[2]->person->email, 'person4@customer.com',
        'Fixtures defined with inline scalar refs should work';
};

subtest 'Fixture chains: a next b next c next d' => sub {
    ok my $item = $fixtures->load('item_1'),
        'We should be able to load a "chain" of fixtures';

    foreach my $name (qw/item_2 item_3 item_4/) {
        ok $fixtures->is_loaded($name),
            "... and '$name', the next item in the chain should be loaded";
    }
};

done_testing;
