use Test::More tests=>48;
use App::SimpleScan::Substitution;

my $sub = new App::SimpleScan::Substitution;

$sub->substitution_value('a', '0', '1', '2');
$sub->substitution_value('b', '0', '1');
$sub->substitution_value('c', '0', '1', '2', '3');
$sub->substitution_value(agent=>'Windows IE 6');

my %map = (
  0 => {a=>0, agent=> 'Windows IE 6', b=>0, c=>0},
  1 => {a=>1, agent=> 'Windows IE 6', b=>0, c=>0},
  2 => {a=>2, agent=> 'Windows IE 6', b=>0, c=>0},
  3 => {a=>0, agent=> 'Windows IE 6', b=>1, c=>0},
  4 => {a=>1, agent=> 'Windows IE 6', b=>1, c=>0},
  5 => {a=>2, agent=> 'Windows IE 6', b=>1, c=>0},
  6 => {a=>0, agent=> 'Windows IE 6', b=>0, c=>1},
  7 => {a=>1, agent=> 'Windows IE 6', b=>0, c=>1},
  8 => {a=>2, agent=> 'Windows IE 6', b=>0, c=>1},
  9 => {a=>0, agent=> 'Windows IE 6', b=>1, c=>1},
 10 => {a=>1, agent=> 'Windows IE 6', b=>1, c=>1},
 11 => {a=>2, agent=> 'Windows IE 6', b=>1, c=>1},
 12 => {a=>0, agent=> 'Windows IE 6', b=>0, c=>2},
 13 => {a=>1, agent=> 'Windows IE 6', b=>0, c=>2},
 14 => {a=>2, agent=> 'Windows IE 6', b=>0, c=>2},
 15 => {a=>0, agent=> 'Windows IE 6', b=>1, c=>2},
 16 => {a=>1, agent=> 'Windows IE 6', b=>1, c=>2},
 17 => {a=>2, agent=> 'Windows IE 6', b=>1, c=>2},
 18 => {a=>0, agent=> 'Windows IE 6', b=>0, c=>3},
 19 => {a=>1, agent=> 'Windows IE 6', b=>0, c=>3},
 20 => {a=>2, agent=> 'Windows IE 6', b=>0, c=>3},
 21 => {a=>0, agent=> 'Windows IE 6', b=>1, c=>3},
 22 => {a=>1, agent=> 'Windows IE 6', b=>1, c=>3},
 23 => {a=>2, agent=> 'Windows IE 6', b=>1, c=>3},
);

my %comb = (
 0 => [0, 0, 0, 0],
 1 => [1, 0, 0, 0],
 2 => [2, 0, 0, 0],
 3 => [0, 0, 1, 0],
 4 => [1, 0, 1, 0],
 5 => [2, 0, 1, 0],
 6 => [0, 0, 0, 1],
 7 => [1, 0, 0, 1],
 8 => [2, 0, 0, 1],
 9 => [0, 0, 1, 1],
10 => [1, 0, 1, 1],
11 => [2, 0, 1, 1],
12 => [0, 0, 0, 2],
13 => [1, 0, 0, 2],
14 => [2, 0, 0, 2],
15 => [0, 0, 1, 2],
16 => [1, 0, 1, 2],
17 => [2, 0, 1, 2],
18 => [0, 0, 0, 3],
19 => [1, 0, 0, 3],
20 => [2, 0, 0, 3],
21 => [0, 0, 1, 3],
22 => [1, 0, 1, 3],
23 => [2, 0, 1, 3],
);

for $i (0..23) {
  my @result = $sub->_comb($i, a=>3, b=>2, c=>4, agent=>1);
  is_deeply \@result, $comb{$i}, "index converted properly";
}

for $i (0..23) {
  my %result = $sub->_comb_index($i, a=>3, b=>2, c=>4, agent=>1);
  is_deeply \%result, $map{$i}, "index mapped properly";
}

