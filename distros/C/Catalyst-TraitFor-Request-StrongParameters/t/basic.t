BEGIN {
  use Test::Most;
  eval "use Catalyst 5.90090; 1" || do {
    plan skip_all => "Need a newer version of Catalyst => $@";
  };
}
{
  package MyApp::Controller::Root;
  use warnings;
  use strict;
  use Data::Dumper;
  use base 'Catalyst::Controller';

  sub body :Local {
    my ($self, $c) = @_;
    my %clean = $c->req->strong_body
      ->permitted(['person'], +{'email' => []})
      ->namespace(['person'])
      ->permitted(
          'name',
          'age',
          'address' => ['street' => ['number', 'name', +{'memo'=> []} ], 'zip'],
          +{'credit_cards' => [
              'number',
              'exp',
              +{detail=>[qw/one two/]},
              'exp' => [qw/year month day/],
              +{note => []} 
          ]},
      )->to_hash;

    my $dumped = Dumper(\%clean);
    $c->res->body($dumped);
  }

  sub data :Local {
    my ($self, $c) = @_;
    my %clean = $c->req->strong_data
      ->permitted(
        ['person'],
        'name',
        'age',
        'address' => ['street' => ['number', 'name', +{'memo'=> []} ], 'zip'],
        +{'credit_cards' => [
            'number',
            'exp',
            'exp' => [qw/year month day/],
            +{detail=>[qw/one two/]},
            +{note => []},
        ]},
        +{'email' => []},
      )->to_hash;

    my $dumped = Dumper(\%clean);
    $c->res->body($dumped);
  }

  sub query :Local {
    my ($self, $c) = @_;
    my %clean = $c->req->strong_query( name=>[qw/first last/] )->required('username')->to_hash;
    my $dumped = Dumper(\%clean);
    $c->res->body($dumped);
  }

  sub end :Action {
    my ($self, $c) = @_;
    if($c->has_errors) {
      $c->res->body($c->last_error);
      $c->clear_errors;
    }
  }

  $INC{'MyApp/Controller/Root.pm'} = __FILE__;

  package MyApp;
  use Catalyst;
  
  MyApp->request_class_traits(['Catalyst::TraitFor::Request::StrongParameters']);
  MyApp->setup;
}

use HTTP::Request::Common;
use Catalyst::Test 'MyApp';


{
  ok my $res = request GET '/root/query?username=jjn&name.first=john&name.last=napiorkowski';
  ok my $data = eval $res->content;
  is_deeply $data, +{
    username => 'jjn',
    name => +{
      first => 'john',
      last => 'napiorkowski',
    },
  }
}

{
  ok my $res = request GET '/root/query?name.first=john&name.last=napiorkowski';
  is $res->content, "Required parameter 'username' is missing.";
}

{
  ok my $body_parameters = [
    'person.name' => 2,
    'person.name' => 'John', # flatten array should jsut pick the last one
    'person.age' => '52',
    'person.address.street.number' => '15604',
    'person.address.street.name' => 'Harry Lind Road',
    'person.address.street.memo[0]' => 'test1',
    'person.address.street.memo[1]' => 'test2',
    'person.address.zip' => '78621',
    'person.email[0]' => 'jjn1056@gmail.com',
    'person.email[1]' => 'jjn1056@yahoo.com',
    'person.email' => 'jjn1056@example.com',
    'person.credit_cards[0].number' => '245345345345345',
    'person.credit_cards[0].exp' => '2024-01-01',
    'person.credit_cards[1].number' => '666677777888878',
    'person.credit_cards[1].exp' => '2024-01-01',
    'person.credit_cards[1].detail[0].one' => '1one',
    'person.credit_cards[1].detail[0].two' => '1two',
    'person.credit_cards[1].detail[1].one' => '2one',
    'person.credit_cards[1].detail[1].two' => '2two',
    'person.credit_cards[1].detail[1].three' => '2three',
    'person.credit_cards[2].number' => '88888888888',
    'person.credit_cards[2].exp.year' => '3024',
    'person.credit_cards[2].exp.month' => '12',
    'person.credit_cards[2].exp.day' => '1',
    'person.credit_cards[2].note[0]' => '1',
    'person.credit_cards[2].note[1]' => '2',
    'person.credit_cards[2].note[2]' => '3',
    'person.credit_cards[2]._add' => 1,
    'person.credit_cards[3]._add' => 1,
    'person.credit_cards[].number' => '444444433333',
    'person.credit_cards[].exp' => '4024-01-01',
  ];

  ok my $res = request POST '/root/body', $body_parameters;
  ok my $data = eval $res->content;  
  is_deeply $data, +{
    address => {
      street => {
        memo => [
          "test1",
          "test2",
        ],
        name => "Harry Lind Road",
        number => 15604,
      },
      zip => 78621,
    },
    age => 52,
    credit_cards => [
      {
        exp => "2024-01-01",
        number => "245345345345345",
      },
      {
        detail => [
          {
            one => "1one",
            two => "1two",
          },
          {
            one => "2one",
            two => "2two",
          },
        ],
        exp => "2024-01-01",
        number => "666677777888878",
      },
      {
        exp => {
          day => 1,
          month => 12,
          year => 3024,
        },
        note => [
          1,
          2,
          3,
        ],
        number => "88888888888",
      },
      {
        exp => "4024-01-01",
        number => "444444433333",
      },
    ],
    email => [
      "jjn1056\@gmail.com",
      "jjn1056\@yahoo.com",
    ],
    name => "John",
  };
}

{
  ok my $data = [
    'person.name' => 2,
    'person.name' => 'John', # flatten array should jsut pick the last one
    'person.age' => '52',
    'person.address.street.number' => '15604',
    'person.address.street.name' => 'Harry Lind Road',
    'person.address.street.memo[0]' => 'test1',
    'person.address.street.memo[1]' => 'test2',
    'person.address.zip' => '78621',
    'person.email[0]' => 'jjn1056@gmail.com',
    'person.email[1]' => 'jjn1056@yahoo.com',
    'person.credit_cards[0].number' => '245345345345345',
    'person.credit_cards[0].exp' => '2024-01-01',
    'person.credit_cards[1].number' => '666677777888878',
    'person.credit_cards[1].exp' => '2024-01-01',
    'person.credit_cards[1].detail[0].one' => '1one',
    'person.credit_cards[1].detail[0].two' => '1two',
    'person.credit_cards[1].detail[1].one' => '2one',
    'person.credit_cards[1].detail[1].two' => '2two',
    'person.credit_cards[1].detail[1].three' => '2three',
    'person.credit_cards[2].number' => '88888888888',
    'person.credit_cards[2].exp.year' => '3024',
    'person.credit_cards[2].exp.month' => '12',
    'person.credit_cards[2].exp.day' => '1',
    'person.credit_cards[2].note[0]' => '1',
    'person.credit_cards[2].note[1]' => '2',
    'person.credit_cards[2].note[2]' => '3',
    'person.credit_cards[2]._add' => 1,
    'person.credit_cards[3]._add' => 1,

    'person.credit_cards[].number' => '444444433333',
    'person.credit_cards[].exp' => '4024-01-01',
  ];
  ok my $res = request POST '/root/data', $data;
  ok my $content = eval $res->content;
  is_deeply $content, +{
    address => {
      street => {
        memo => [
          "test1",
          "test2",
        ],
        name => "Harry Lind Road",
        number => 15604,
      },
      zip => 78621,
    },
    age => 52,
    credit_cards => [
      {
        exp => "2024-01-01",
        number => "245345345345345",
      },
      {
        detail => [
          {
            one => "1one",
            two => "1two",
          },
          {
            one => "2one",
            two => "2two",
          },
        ],
        exp => "2024-01-01",
        number => "666677777888878",
      },
      {
        exp => {
          day => 1,
          month => 12,
          year => 3024,
        },
        note => [
          1,
          2,
          3,
        ],
        number => "88888888888",
      },
    ],
    email => [
      "jjn1056\@gmail.com",
      "jjn1056\@yahoo.com",
    ],
    name => [2, "John"],
  };

}
done_testing;
