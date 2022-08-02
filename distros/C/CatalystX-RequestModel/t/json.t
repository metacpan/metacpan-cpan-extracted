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
  ok my $data = qq[
    {
      "person":{
        "username": "jjn",
        "first_name": "john",
        "last_name": "napiorkowski",
        "profile": {
          "id": 1,
          "address": "1351 Miliary Road",
          "city": "Little Falls",
          "state_id": 7,
          "zip": "42342",
          "phone_number": 6328641827,
          "birthday": "2222-01-01",
          "registered": false        
        },
        "person_roles": [
          { "role_id": 1 },
          { "role_id": 2 }
        ],
        "credit_cards": [
          { "id":100, "card_number": 111222333444, "expiration": "2222-02-02" },
          { "id":200, "card_number": 888888888888, "expiration": "3333-02-02" },
          { "id":300, "card_number": 333344445555, "expiration": "4444-02-02" }
        ]
      }
    }
  ];

  ok my $res = request POST '/account/json',
    Content_Type => 'application/json',
    Content => $data;
  ok my $data =  eval $res->content; 

  is_deeply $data, +{
    'person_roles' => [
                        {
                          'role_id' => 1
                        },
                        {
                          'role_id' => 2
                        }
                      ],
    'profile' => {
                   'address' => '1351 Miliary Road',
                   'birthday' => '2222-01-01',
                   'id' => 1,
                   'state_id' => 7,
                   'phone_number' => 6328641827,
                   'registered' => 0,
                   'zip' => '42342',
                   'city' => 'Little Falls'
                 },
    'credit_cards' => [
                        {
                          'card_number' => '111222333444',
                          'expiration' => '2222-02-02',
                          'id' => 100
                        },
                        {
                          'id' => 200,
                          'card_number' => '888888888888',
                          'expiration' => '3333-02-02'
                        },
                        {
                          'id' => 300,
                          'card_number' => '333344445555',
                          'expiration' => '4444-02-02'
                        }
                      ],
    'first_name' => 'john',
    'username' => 'jjn',
    'last_name' => 'napiorkowski' 
  };
}

{
  ok my $data = qq[
    {
      "info":{
        "username": "jjn",
        "first_name": "john",
        "last_name": "napiorkowski"
      }
    }
  ];

  ok my $res = request POST '/account/jsonquery?page=10;offset=100;search=nope',
    Content_Type => 'application/json',
    Content => $data;

  ok my $data = eval $res->content;
  
  is_deeply $data, +{
    get => {
      offset => 100,
      page => 10,
      search => "nope",
    },
    post => {
      first_name => "john",
      last_name => "napiorkowski",
      username => "jjn",
    },
  };
}

{
  ok my $data = qq[
    {
      "info":{
        "username": "jjn",
      }
  ];

  ok my $res = request POST '/account/jsonquery?page=10;offset=100;search=nope',
    Content_Type => 'application/json',
    Content => $data;

  is $res->code, 400;
}

done_testing;
