#-*- mode: perl;-*-

package main;

use strict;

use Test::More tests => 70;

use_ok('Algorithm::SkipList', '1.02');

my $l = new Algorithm::SkipList();
foreach my $key (1..9) {
  $l->insert($key, -$key);
}
ok($l->size == 9);

my @keys = $l->keys();
ok(@keys == $l->size);
ok(@keys == 9);

foreach my $key (1..9) {
  @keys = $l->keys($key);
  ok(@keys == (10-$key));
  ok($keys[0] == $key);
  @keys = $l->keys($key, undef,$key);
  ok(@keys == 1);
  ok($keys[0] == $key);
}

foreach my $key (1..5) {
  @keys = $l->keys($key, undef, $key+4);
  ok(@keys == 5);
  foreach my $k ($key..$key+4) {
    ok(shift @keys == $k);
  }
  
}

# TODO: test where high > greatest key



