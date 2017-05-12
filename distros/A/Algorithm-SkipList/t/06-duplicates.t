#-*- mode: perl;-*-

package main;

use strict;

use Test::More tests => 19;

use Algorithm::SkipList 0.70;

my $List;

eval {
  $List = new Algorithm::SkipList();
};
ok( defined $List );

my $count = 0;
for (1..10) {
  $List->insert('x', ++$count);
}
ok( $List->size == 1);

my @values = $List->find_duplicates('x');
ok( @values == 1);

eval {
  $List = new Algorithm::SkipList( duplicates => 0);
};
ok( defined $List );

$count = 0;
for (1..10) {
  $List->insert('x', ++$count);
}
ok( $List->size == 1);

$List->insert('w', -1); # insert predecessor and successor
$List->insert('y', -1);

@values = $List->find_duplicates('x');
ok( @values == 1);


eval {
  $List = new Algorithm::SkipList( duplicates => 1);
};
ok( defined $List );

$count = 0;
for (1..10) {
  $List->insert('x', ++$count);
}
ok( $List->size == 10);

$List->insert('w', -1); # insert predecessor and successor
$List->insert('y', -1);

@values = $List->find_duplicates('x');

ok( @values == 10);

while (my $value2 = shift @values) {
  my $value = $List->delete('x');
  ok($value == $value2);
}

