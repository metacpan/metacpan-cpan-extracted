use Array::Join;
use Test::More;
use Data::Dumper;
use List::MoreUtils qw/uniq/;

sub dumper { Data::Dumper->new([@_])->Indent(0)->Sortkeys(1)->Terse(1)->Useqq(1)->Dump }

use strict;

$\ = "\n"; $, = "\t";

my @arr_a = (
  { id => 1, foo => 'apple',  price => 10 },
  { id => 2, foo => 'banana', price => 20 },
  { id => 3, foo => 'cherry', price => 30 },
  { id => 4, foo => 'date',   price => 40 },
  { id => 5, foo => 'elder',  price => 50 },
  { id => 6, foo => 'fig',    price => 60 },
  { id => 7, foo => 'grape',  price => 70 },
  { id => 8, foo => 'honey',  price => 80 },
  { id => 9, foo => 'kiwi',   price => 90 },
  { id => 10,foo => 'lemon',  price => 100 },
  { id => 11,foo => 'mango',  price => 110 },
  { id => 12,foo => 'nectar', price => 120 },
  { id => 13,foo => 'olive',  price => 130 },
  { id => 14,foo => 'peach',  price => 140 },
  { id => 15,foo => 'quince', price => 150 },
  { id => 16,foo => 'rasp',   price => 160 },
  { id => 17,foo => 'straw',  price => 170 },
  { id => 18,foo => 'tang',   price => 180 },
  { id => 19,foo => 'ugli',   price => 190 },
  { id => 20,foo => 'voav',   price => 200 },
);

my @arr_b = (
  { key => 'apple',   bar => 'red',    desc => 'fruit' },
  { key => 'banana',  bar => 'yellow', desc => 'fruit' },
  { key => 'carrot',  bar => 'orange', desc => 'vegetable' },
  { key => 'date',    bar => 'brown',  desc => 'fruit' },
  { key => 'eggplant',bar => 'purple', desc => 'vegetable' },
  { key => 'fig',     bar => 'purple', desc => 'fruit' },
  { key => 'grape',   bar => 'green',  desc => 'fruit' },
  { key => 'honey',   bar => 'gold',   desc => 'sweetener' },
  { key => 'iceberg', bar => 'green',  desc => 'lettuce' },
  { key => 'jalapeno',bar => 'green',  desc => 'pepper' },
  { key => 'kiwi',    bar => 'brown',  desc => 'fruit' },
  { key => 'lemon',   bar => 'yellow', desc => 'fruit' },
  { key => 'mango',   bar => 'orange', desc => 'fruit' },
  { key => 'nectar',  bar => 'orange', desc => 'fruit' },
  { key => 'onion',   bar => 'white',  desc => 'vegetable' },
  { key => 'peach',   bar => 'pink',   desc => 'fruit' },
  { key => 'quince',  bar => 'yellow', desc => 'fruit' },
  { key => 'radish',  bar => 'red',    desc => 'vegetable' },
  { key => 'straw',   bar => 'red',    desc => 'fruit' },
  { key => 'tomato',  bar => 'red',    desc => 'fruit' },
);

my ($lookup, $sub); 

$sub = sub { shift->{desc} };
$lookup = Array::Join::make_lookup(\@arr_b, $sub);
is_deeply($lookup, {"fruit" => [0,1,3,5,6,10,11,12,13,15,16,18,19],"lettuce" => [8],"pepper" => [9],"sweetener" => [7],"vegetable" => [2,4,14,17]}, "lookup 1");

for my $k (keys $lookup->%*) {
    ok(1 == (scalar uniq ($k, map { $sub->($arr_b[$_]) } $lookup->{$k}->@*)), "key $k")
}

$sub = sub { (1 + int(shift->{price} / 30)) * 30 };
$lookup = Array::Join::make_lookup(\@arr_a, $sub);

is_deeply($lookup, {"120" => [8,9,10],"150" => [11,12,13],"180" => [14,15,16],"210" => [17,18,19],"30" => [0,1],"60" => [2,3,4],"90" => [5,6,7]}, "lookup 2");

for my $k (sort { $a <=> $b } keys $lookup->%*) {
    ok(1 == (scalar uniq ($k, map { $sub->($arr_a[$_]) } $lookup->{$k}->@*)), "key $k")
}
done_testing()
