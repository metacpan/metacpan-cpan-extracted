#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Catalyst::TraitFor::Controller::jQuery::jqGrid::Search;
use Data::Dumper;


my @tests = (
  {
    name=>'empty and',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"AND","rules":[],"groups":[]}',
    },
    result=>{},
  },
  {
    name=>'empty or',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"OR","rules":[],"groups":[]}',
    },
    result=>{},
  },
  {
    name=>'empty and in empty and',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"AND","rules":[],"groups":[{"groupOp":"AND","rules":[],"groups":[]}]}',
    },
    result=>{'-and'=>[{}]},
  },
  {
    name=>'empty or in empty or',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"OR","rules":[],"groups":[{"groupOp":"OR","rules":[],"groups":[]}]}',
    },
    result=>{'-or'=>[{}]},
  },
  {
    name=>'empty and in empty and in empty and',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"AND","rules":[],"groups":[{"groupOp":"AND","rules":[],"groups":[{"groupOp":"AND","rules":[],"groups":[]}]}]}',
    },
    result=>{'-and'=>[{'-and'=>[{}]}]},
  },
  {
    name=>'empty and in empty or in empty and',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"AND","rules":[],"groups":[{"groupOp":"OR","rules":[],"groups":[{"groupOp":"AND","rules":[],"groups":[]}]}]}',
    },
    result=>{'-and'=>[{'-or'=>[{}]}]},
  },
  {
    name=>'empty or in empty and in empty or',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"OR","rules":[],"groups":[{"groupOp":"AND","rules":[],"groups":[{"groupOp":"OR","rules":[],"groups":[]}]}]}',
    },
    result=>{'-or'=>[{'-and'=>[{}]}]},
  },
  {
    name=>'basic all x = y',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"AND","rules":[{"field":"x","op":"cn","data":"y"}],"groups":[]}',
    },
    result=>{'-and'=>[{'x'=>{'-like'=>'%y%'}}]},
  },
  {
    name=>'basic any x = y',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"OR","rules":[{"field":"x","op":"cn","data":"y"}],"groups":[]}',
    },
    result=>{'-or'=>[{'x'=>{'-like'=>'%y%'}}]},
  },
  {
    name=>'all a = 1, b = 2',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"AND","rules":[{"field":"a","op":"eq","data":"1"},{"field":"b","op":"eq","data":"2"}],"groups":[]}',
    },
    result=>{'-and'=>[{'a'=>{'='=>'1'}},{'b'=>{'='=>'2'}}]},
  },
  {
    name=>'any a = 1, b = 2',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"OR","rules":[{"field":"a","op":"eq","data":"1"},{"field":"b","op":"eq","data":"2"}],"groups":[]}',
    },
    result=>{'-or'=>[{'a'=>{'='=>'1'}},{'b'=>{'='=>'2'}}]},
  },
  {
    name=>'all a = 1, b = 2, c = 3',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"AND","rules":[{"field":"a","op":"eq","data":"1"},{"field":"b","op":"eq","data":"2"},{"field":"c","op":"eq","data":"3"}],"groups":[]}',
    },
    result=>{'-and'=>[{'a'=>{'='=>'1'}},{'b'=>{'='=>'2'}},{'c'=>{'='=>'3'}}]},
  },
  {
    name=>'any a = 1, b = 2, c = 3',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"OR","rules":[{"field":"a","op":"eq","data":"1"},{"field":"b","op":"eq","data":"2"},{"field":"c","op":"eq","data":"3"}],"groups":[]}',
    },
    result=>{'-or'=>[{'a'=>{'='=>'1'}},{'b'=>{'='=>'2'}},{'c'=>{'='=>'3'}}]},
  },
  {
    name=>'((a = "1" OR b = "2") AND c = "3")',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"AND","rules":[{"field":"c","op":"eq","data":"3"}],"groups":[{"groupOp":"OR","rules":[{"field":"a","op":"eq","data":"1"},{"field":"b","op":"eq","data":"2"}],"groups":[]}]}',
    },
    result=>{'-and'=>[{'-or'=>[{'a'=>{'='=>'1'}},{'b'=>{'='=>'2'}}]},[{'c'=>{'='=>'3'}}]]},
  },
  {
    name=>'((a = "1" AND b = "2") OR c = "3")',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"OR","rules":[{"field":"c","op":"eq","data":"3"}],"groups":[{"groupOp":"AND","rules":[{"field":"a","op":"eq","data":"1"},{"field":"b","op":"eq","data":"2"}],"groups":[]}]}',
    },
    result=>{'-or'=>[{'-and'=>[{'a'=>{'='=>'1'}},{'b'=>{'='=>'2'}}]},[{'c'=>{'='=>'3'}}]]},
  },
  {
    name=>'((a = "1" OR b = "2") AND c = "3" AND d = "4")',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"AND","rules":[{"field":"c","op":"eq","data":"3"},{"field":"d","op":"eq","data":"4"}],"groups":[{"groupOp":"OR","rules":[{"field":"a","op":"eq","data":"1"},{"field":"b","op":"eq","data":"2"}],"groups":[]}]}',
    },
    result=>{'-and'=>[{'-or'=>[{'a'=>{'='=>'1'}},{'b'=>{'='=>'2'}}]},[{'c'=>{'='=>'3'}},{'d'=>{'='=>'4'}}]]},
  },
  {
    name=>'((a = "1" OR b = "2") AND (c = "3" OR d = "4"))',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"AND","rules":[],"groups":[{"groupOp":"OR","rules":[{"field":"a","op":"eq","data":"1"},{"field":"b","op":"eq","data":"2"}],"groups":[]},{"groupOp":"OR","rules":[{"field":"c","op":"eq","data":"3"},{"field":"d","op":"eq","data":"4"}],"groups":[]}]}',
    },
    result=>{'-and'=>[{'-or'=>[{'a'=>{'='=>'1'}},{'b'=>{'='=>'2'}}]},{'-or'=>[{'c'=>{'='=>'3'}},{'d'=>{'='=>'4'}}]}]},
  },
  {
    name=>'and cascade: (((((((((((a = "1")))))))))))',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"AND","rules":[],"groups":[{"groupOp":"AND","rules":[],"groups":[{"groupOp":"AND","rules":[],"groups":[{"groupOp":"AND","rules":[],"groups":[{"groupOp":"AND","rules":[],"groups":[{"groupOp":"AND","rules":[],"groups":[{"groupOp":"AND","rules":[],"groups":[{"groupOp":"AND","rules":[],"groups":[{"groupOp":"AND","rules":[],"groups":[{"groupOp":"AND","rules":[],"groups":[{"groupOp":"AND","rules":[{"field":"a","op":"eq","data":"1"}],"groups":[]}]}]}]}]}]}]}]}]}]}]}',
    },
    result=>{'-and'=>[{'-and'=>[{'-and'=>[{'-and'=>[{'-and'=>[{'-and'=>[{'-and'=>[{'-and'=>[{'-and'=>[{'-and'=>[{'-and'=>[{'a'=>{'='=>'1'}}]}]}]}]}]}]}]}]}]}]}]},
  },
  {
    name=>'(((a = "1" OR b = "2") AND c = "3") OR ((d = "4" OR e = "5") AND f = "6"))',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"OR","rules":[],"groups":[{"groupOp":"AND","rules":[{"field":"c","op":"eq","data":"3"}],"groups":[{"groupOp":"OR","rules":[{"field":"a","op":"eq","data":"1"},{"field":"b","op":"eq","data":"2"}],"groups":[]}]},{"groupOp":"AND","rules":[{"field":"f","op":"eq","data":"6"}],"groups":[{"groupOp":"OR","rules":[{"field":"d","op":"eq","data":"4"},{"field":"e","op":"eq","data":"5"}],"groups":[]}]}]}',
    },
    result=>{'-or'=>[{'-and'=>[{'-or'=>[{'a'=>{'='=>'1'}},{'b'=>{'='=>'2'}}]},[{'c'=>{'='=>'3'}}]]},{'-and'=>[{'-or'=>[{'d'=>{'='=>'4'}},{'e'=>{'='=>'5'}}]},[{'f'=>{'='=>'6'}}]]}]},
  },
  {
    name=>'(((a = "1" OR b = "2") AND c = "3" AND d = "4") OR ((e = "5") AND f = "6") OR g = "7")',
    search=>{ '_search'=>'true',
      'filters'=>'{"groupOp":"OR","rules":[{"field":"g","op":"eq","data":"7"}],"groups":[{"groupOp":"AND","rules":[{"field":"c","op":"eq","data":"3"},{"field":"d","op":"eq","data":"4"}],"groups":[{"groupOp":"OR","rules":[{"field":"a","op":"eq","data":"1"},{"field":"b","op":"eq","data":"2"}],"groups":[]}]},{"groupOp":"AND","rules":[{"field":"f","op":"eq","data":"6"}],"groups":[{"groupOp":"AND","rules":[{"field":"e","op":"eq","data":"5"}],"groups":[]}]}]}',
    },
    result=>{'-or'=>[{'-and'=>[{'-or'=>[{'a'=>{'='=>'1'}},{'b'=>{'='=>'2'}}]},[{'c'=>{'='=>'3'}},{'d'=>{'='=>'4'}}]]},{'-and'=>[{'-and'=>[{'e'=>{'='=>'5'}}]},[{'f'=>{'='=>'6'}}]]},[{'g'=>{'='=>'7'}}]]},
  },
#  {
#    name=>'
#
#',
#    search=>{ '_search'=>'true',
#      'filters'=>'
#
#',
#    },
#    result=>{
#
#},
#  },
);

plan tests => @tests + 1;

can_ok( 'Catalyst::TraitFor::Controller::jQuery::jqGrid::Search', 'jqGrid_search');

for my $t (@tests) {
  is_deeply(Catalyst::TraitFor::Controller::jQuery::jqGrid::Search->jqGrid_search($t->{search}), $t->{result}, $t->{name});
}


