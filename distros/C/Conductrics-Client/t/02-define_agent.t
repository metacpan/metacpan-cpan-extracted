#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use JSON::MaybeXS;
use Test::Deep;
use Test::Deep::JSON;

my $env_found;
CHECK_ENV: {
    my @cvars = qw/ apikey Mng_apikey ownerCode /;
    for my $v (@cvars) {
	unless (exists $ENV{"Conductrics_$v"}) {
	    plan skip_all=> join ("\n",
				  "\$ENV{Conductrics_$v} has to be defined for this test",
				  "environment vars required:",
				  map {"Conductrics_$_"} @cvars);
	    last CHECK_ENV;
	}
    }
    $env_found=1;
}

if ($env_found) {
    plan tests=>9;
}

use_ok('Conductrics::Client');

my $client = Conductrics::Client->new(apiKey=>$ENV{Conductrics_Mng_apikey}, ownerCode=>$ENV{Conductrics_ownerCode}, baseUrl=>'http://api.conductrics.com/');

ok($client);
isa_ok($client, "Conductrics::Client");

eval {
    $client->delete_agent('YourSite');
};
eval {  
    $client->delete_agent('mysite');
};

my $read_data = q(
{
  "name": "YourSite",
  "code": "YourSite",
  "points": [
    {
      "code": "home",
      "decisions": [
        {
          "code": "colour",
          "choices": [
            {
              "code": "red"
            },
            {
              "code": "green"
            },
            {
              "code": "blue"
            }
          ]
        },
        {
          "code": "font",
          "choices": [
            {
              "code": "helvetica"
            },
            {
              "code": "verdana"
            }
          ]
        }
      ]
    },
    {
      "code": "auction",
      "decisions": [
        {
          "code": "mood",
          "choices": [
            {
              "code": "entusiastic"
            },
            {
              "code": "winning"
            },
            {
              "code": "gambling"
            }
          ]
        },
        {
          "code": "product",
          "choices": [
            {
              "code": "electronics"
            },
            {
              "code": "food"
            }
          ]
        }
      ]
    }
  ],
  "goals": [
    {
      "code": "subscribed",
      "settings": {
        "default": 5,
        "limit": 5
      }
    },
    {
      "code": "sold",
      "settings": {
        "default": 3,
        "limit": 1
      }
    },
    {
      "code": "registered",
      "name": "registered",
      "settings": {
        "default": 2,
        "limit": 1
      }
    },
    {
      "code": "home",
      "name": "Hit home",
      "type": "sys-dec",
      "settings": {
        "min": 1,
        "max": 3,
        "default": 0,
        "limit": 1
      }
    },
    {
      "code": "auction",
      "name": "Hit auction",
      "type": "sys-dec"
    }
  ]
}
);

my $data = JSON::MaybeXS::decode_json($read_data);
$data->{owner}=$client->ownerCode;

ok($client->validate_agent($client->get_json_schema, JSON::MaybeXS::encode_json($data) ), "json agent description is valid");

ok($client->create_agent('YourSite', JSON::MaybeXS::encode_json($data)), "With real data");

#print JSON::MaybeXS::encode_json($data);




my $agent_def = $client->define_agent(
                                     'mysite', 
   				     $client->define_goals( qw/ subscription sold win registration / ), 
				     [ $client->define_decision_point(
								     'home',
			                                             $client->define_decision( 'colour', qw/red green blue/ ),
			                                             $client->define_decision( 'font', qw/arial verdana/ )
								    ),
				       $client->define_decision_point(
								     'auction',
			                                             $client->define_decision( 'product', qw/tablet food beverage/ ),
			                                             $client->define_decision( 'sort_by', qw/lowprice expiration/ )
								    )
			             ]			    
			            );


ok($client->validate_agent($client->get_json_schema, JSON::MaybeXS::encode_json($agent_def)), "json agent_def description is valid");

cmp_deeply($agent_def, JSON::MaybeXS::decode_json(JSON::MaybeXS::encode_json($agent_def)), "my agent is well defined");
ok($client->create_agent('mysite', $agent_def), "mysite agent created");

my $schema = $client->get_json_schema();
my $agent1_def = {name=>'Agent-1', code=>'Agent-1'};
my $valid = $client->validate_agent($schema, $agent1_def);
SKIP: {
    skip "Agent-1 not ready", 1 unless ($valid);
    
    ok($client->create_agent('Agent-1', {name=>'Agent-1', code=>'Agent-1'}), 'Agent-1 created');
}



exit;

#
#  __DATA__ contains a dump of the Condutricts agent from the Conductrics console.
#

__DATA__

{
  "name": "Mysite",
  "points": [
    {
      "code": "home",
      "decisions": [
        {
          "code": "colour",
          "choices": [
            {
              "code": "red",
            },
            {
              "code": "green",
            },
            {
              "code": "blue",
            }
          ],
        },
        {
          "code": "font",
          "choices": [
            {
              "code": "helvetica",
            },
            {
              "code": "verdana",
            }
          ]
        }
      ],
    },
    {
      "code": "auction",
      "decisions": [
        {
          "code": "mood",
          "choices": [
            {
              "code": "entusiastic",
            },
            {
              "code": "winning",
            },
            {
              "code": "gambling",
            }
          ]
        },
        {
          "code": "product",
          "choices": [
            {
              "code": "electronics",
            },
            {
              "code": "food",
            }
          ]
        }
      ]
    }
  ],
  "goals": [
    {
      "code": "subscrived",
      "settings": {
        "default": 5,
        "limit": 5
      }
    },
    {
      "code": "sold",
      "settings": {
        "default": 3,
        "limit": 1
      }
    },
    {
      "code": "registered",
      "name": "registered",
      "settings": {
        "default": 2,
        "limit": 1
      }
    },
    {
      "code": "home",
      "name": "Hit home",
      "type": "sys-dec",
      "settings": {
        "min": 1,
        "max": 3,
        "default": 0,
        "limit": 1
      }
    },
    {
      "code": "auction",
      "name": "Hit auction",
      "type": "sys-dec"
    }
  ],
  "learning": {
    "explorationRate": 1,
    "controlGroupRate": 0.1
  },
  "created": 1433838194,
  "ts": 1433838624,
  "status": "enabled",
  "settings": {
    "sessions": {
      "sticky": true,
      "timeout": 1081800,
      "visitLen": 14400
    },
    "cookies": {
      "enabled": true
    },
    "allowUndo": false
  },
  "targeting": {
    "segments": [],
    "features": [
      {
        "code": "sys-dec::home-colour-red-font-helvetica",
        "name": "From home: red, helvetica",
        "type": "sys-dec"
      },
      {
        "code": "sys-dec::home-colour-red-font-verdana",
        "name": "From home: red, verdana",
        "type": "sys-dec"
      },
      {
        "code": "sys-dec::home-colour-green-font-helvetica",
        "name": "From home: green, helvetica",
        "type": "sys-dec"
      },
      {
        "code": "sys-dec::home-colour-green-font-verdana",
        "name": "From home: green, verdana",
        "type": "sys-dec"
      },
      {
        "code": "sys-dec::home-colour-blue-font-helvetica",
        "name": "From home: blue, helvetica",
        "type": "sys-dec"
      },
      {
        "code": "sys-dec::home-colour-blue-font-verdana",
        "name": "From home: blue, verdana",
        "type": "sys-dec"
      },
      {
        "code": "sys-dec::auction-mood-entusiastic",
        "name": "From auction: entusiastic",
        "type": "sys-dec"
      },
      {
        "code": "sys-dec::auction-mood-winning",
        "name": "From auction: winning",
        "type": "sys-dec"
      },
      {
        "code": "sys-dec::auction-mood-gambling",
        "name": "From auction: gambling",
        "type": "sys-dec"
      },
      {
        "code": "sys-dec::auction-mood-entusiastic-product-electronics",
        "name": "From auction: entusiastic, electronics",
        "type": "sys-dec"
      },
      {
        "code": "sys-dec::auction-mood-entusiastic-product-food",
        "name": "From auction: entusiastic, food",
        "type": "sys-dec"
      },
      {
        "code": "sys-dec::auction-mood-winning-product-electronics",
        "name": "From auction: winning, electronics",
        "type": "sys-dec"
      },
      {
        "code": "sys-dec::auction-mood-winning-product-food",
        "name": "From auction: winning, food",
        "type": "sys-dec"
      },
      {
        "code": "sys-dec::auction-mood-gambling-product-electronics",
        "name": "From auction: gambling, electronics",
        "type": "sys-dec"
      },
      {
        "code": "sys-dec::auction-mood-gambling-product-food",
        "name": "From auction: gambling, food",
        "type": "sys-dec"
      }
    ]
  },
  "_computed": {
    "status": "enabled",
    "today": 1433808000,
    "history": {
      "dateFrom": 1433808000,
      "dateThru": 1433808000
    }
  }
}
