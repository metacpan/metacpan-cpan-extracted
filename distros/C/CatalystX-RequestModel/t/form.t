BEGIN {
  use Test::Most;
  eval "use Catalyst 5.90090; 1" || do {
    plan skip_all => "Need a newer version of Catalyst => $@";
  };
}

use Test::Lib;
use HTTP::Request::Common;
use Catalyst::Test 'Example';

{
  ok my $body_parameters = [
    'person.first_name' => 2,
    'person.first_name' => 'John', # flatten array should just pick the last one
    'person.last_name' => 'Napiorkowski',
    'person.username' => 'jjn',
    'person.notes' => '{"test":"one", "foo":"bar"}',
    'person.maybe_array' => 'one',
    'person.maybe_array2' => 'one',
    'person.maybe_array2' => 'two',
    'person.indexed[0]' => 100,
    'person.indexed[1]' => 200,
    'person.indexed[]' => 300,
    'person.profile.address' => '15604 Harry Lind Road',
    'person.profile.birthday' => '2000-01-01',
    'person.profile.city' => 'Elgin',
    'person.profile.id' => 1,
    'person.profile.phone_number' => 16467081837,
    'person.profile.registered' => 0,
    'person.profile.registered' => 'sdfsdfsdfsd',
    'person.profile.state_id' => 2,
    'person.profile.status' => '',
    'person.profile.status' => 'pending',
    'person.profile.zip' => 78621,
    'person.credit_cards[0]._delete' => 0,
    'person.credit_cards[0].card_number' => 1231231231,
    'person.credit_cards[0].expiration' => '3000-01-01',
    'person.credit_cards[0].id' => 1,
    'person.credit_cards[1]._delete' => 0,
    'person.credit_cards[1].card_number' => 44444455555,
    'person.credit_cards[1].expiration' => '4000-01-01',
    'person.credit_cards[1].id' => 2,
    'person.credit_cards[1]._delete' => 0,
    'person.credit_cards[].card_number' => 888888899,
    'person.credit_cards[].expiration' => '5000-01-01',
    'person.credit_cards[].id' => 3,
    'person.person_roles[0]._nop' => 1,
    'person.person_roles[1].role_id' => 1,
    'person.person_roles[2].role_id' => 2, 
  ];

  ok my $res = request POST '/account/one', $body_parameters;
  ok my $data = eval $res->content;  
 
  is_deeply $data, +{
    credit_cards => [
      {
        _delete => 0,
        card_number => "1231231231",
        expiration => "3000-01-01",
        id => 1,
      },
      {
        _delete => 0,
        card_number => "44444455555",
        expiration => "4000-01-01",
        id => 2,
      },
      {
        card_number => "888888899",
        expiration => "5000-01-01",
        id => 3,
      },
    ],
    empty => undef,
    empty_array => [],
    first_name => "John",
    indexed => [
      100,
      200,
      300,
    ],
    last_name => "Napiorkowski",
    maybe_array => "one",
    maybe_array2 => [
      "one",
      "two",
    ],
    notes => {
      foo => "bar",
      test => "one",
    },
    person_roles => [
      {
        role_id => 1,
      },
      {
        role_id => 2,
      },
    ],
    profile => {
      address => "15604 Harry Lind Road",
      birthday => "2000-01-01",
      city => "Elgin",
      id => 1,
      phone_number => "16467081837",
      registered => 1,
      state_id => 2,
      status => "pending",
      zip => 78621,
    },
    username => [
      "jjn",
    ],
  };
}

{
  ok my $body_parameters = [
    'person.first_name' => 2,
    'person.first_name' => 'John', # flatten array should just pick the last one
    'person.last_name' => 'Napiorkowski',
    'person.username' => 'jjn',
    'person.notes' => '{"test":"one", "foo":"bar"}',
    'person.maybe_array' => 'one',
    'person.maybe_array2' => 'one',
    'person.maybe_array2' => 'two',
    'person.person_roles[0]._nop' => 1,
    'person.person_roles[1].role_id' => 1,
    'person.person_roles[2].role_id' => 2, 
  ];

  ok my $res = request POST '/account/one', $body_parameters;
  ok my $data = eval $res->content;  

  is_deeply $data, +{
    empty => undef,
    empty_array => [],
    first_name => "John",
    last_name => "Napiorkowski",
    maybe_array => "one",
    maybe_array2 => [
      "one",
      "two",
    ],
    notes => {
      foo => "bar",
      test => "one",
    },
    person_roles => [
      {
        role_id => 1,
      },
      {
        role_id => 2,
      },
    ],
    username => [
      "jjn",
    ],
  };
}

{
  ok my $body_parameters = [
    'person.first_name' => 2,
    'person.first_name' => 'John', # flatten array should just pick the last one
    'person.last_name' => 'Napiorkowski',
  ];

  ok my $res = request POST '/account/one', $body_parameters;
  ok my $data =  $res->content;  
  is $res->code, 500;
}

{
  ok my $body_parameters = [
    username => 'jjn',
    password => 'abc123',
  ];

  ok my $res = request POST '/login', $body_parameters;
  ok my $data = eval $res->content;  
  is_deeply $data, +{
    password => "abc123",
    username => "jjn",
  };
}

done_testing;
