#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 9;
use Data::Dumper;


use Data::Abridge qw( abridge_recursive abridge_item abridge_items_recursive );

my $foo = ['Foo'];
is_deeply( abridge_recursive( ['Foo'] ), [ 'Foo' ], );
push @$foo,  $foo;
is_deeply( abridge_recursive( $foo ), [ Foo => {SEEN=>[]} ], );

my $bar = { Bar => 12 };
is_deeply( abridge_recursive( $bar ), { Bar => 12 }, );
$bar->{ barian }  = $bar;
is_deeply( abridge_recursive( $bar ), { Bar => 12, barian => {SEEN=>[]} }, );

$bar->{foo} = $foo;


push @$foo, $bar;
is_deeply( abridge_recursive( $foo ), 
    [ 'Foo', {SEEN=>[]}, {Bar=>12, barian=>{SEEN=>[2]}, foo => {SEEN=>[]}} ], 
);
is_deeply( abridge_recursive( $bar ), 
    {Bar=>12, barian=>{SEEN=>[]}, foo => [ Foo => {SEEN=>['foo']}, {SEEN=>[]}, ] }
);



my @node = map { bless( {next_node => undef}, 'MyNode') } 0..1 ;
$node[0]->{next_node} = $node[1];
$node[1]->{next_node} = $node[0];

is_deeply( abridge_recursive( \@node ), 
[ { MyNode => {
      next_node => {
        MyNode => {
          next_node => {
            SEEN => [0]
          },
        },
      },
    },
  },
  { SEEN => [ 0, MyNode => 'next_node' ] }
]
);

is_deeply( abridge_items_recursive( @node ), 
[ { MyNode => {
      next_node => {
        MyNode => {
          next_node => {
            SEEN => [0]
          },
        },
      },
    },
  },
  { SEEN => [ 0, MyNode => 'next_node' ] }
]
); 




is_deeply( abridge_items_recursive( $foo, @node, $bar ), 
[ [ 
    'Foo', 
    {'SEEN'=>[0]}, 
    {'Bar'    => 12, 
     'foo'    => {'SEEN'=>[0]}, 
     'barian' => {'SEEN' =>[0,2]}
    }
  ],
  { 'MyNode' => { 
      'next_node' => {
        'MyNode' => {
          'next_node' => {'SEEN'=>[1]}
        }
      }
    }
  },
  {'SEEN'=>[1,'MyNode','next_node']},
  {'SEEN'=>[0,2]}
]
);

