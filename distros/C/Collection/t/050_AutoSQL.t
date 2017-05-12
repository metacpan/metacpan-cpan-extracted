#test AutoSQL
use Test::More tests=>7;
use warnings;
use strict;
use Data::Dumper;
use Collection::AutoSQL;
my $coll = new Collection::AutoSQL::;
isa_ok $coll, 'Collection::AutoSQL';
my $q1 = { "test>" => [ 1, 2, 3 ] };
is_deeply $coll->_expand_rules($q1),
  [
    {
        'values' => [ 1, 2, 3 ],
        'term'   => '>',
        'field'  => 'test'
    }
  ],
  'expand rules for {"test>"=>[1,2,3]}';

is $coll->_prepare_where( { "test>" => 2 } ), '(test > 2)',
  'check {"test>"=>2}';
is $coll->_prepare_where( { "test<" => 2 } ), '(test < 2)',
  'check {"test<"=>2}';
is $coll->_prepare_where( { "<test" => 2 } ), '(test < 2)',
  'check {"<test"=>2}';
is $coll->_prepare_where( { "test" => [ 2, 2 ] } ), '(test in (2,2))',
  'check {"test"=>[2,2]}';
my $q2 = { "test" => [ 1, 2, 3 ] };
is_deeply $coll->_expand_rules($q2),
  [
    {
        'values' => [ 1, 2, 3 ],
        'term'   => '=',
        'field'  => 'test'
    }
  ], 'expand rules: { "test" => [ 1, 2, 3 ] }';

