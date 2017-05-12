#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

my $data =  [
  [ qw(0 0) ],
  [ qw(1 2) ],
  [ qw(2 3) ],
  [ qw(10 C) ],
  [ qw(20 P) ],
  [ qw(30 b) ],
  [ qw(40 p) ],
  [ qw(42 r) ],
  [ qw(49 z) ],
  [ qw(50 20) ],
  [ qw(10055 526) ],
  [ qw(100055 p26) ],
  [ qw(1562500000 600000) ],
  [ qw(15625000001 2000002) ],
  [ qw(1562500000112 3000003F) ],
  #[ qw() ],
];

BEGIN {
  use_ok('Data::ID::URL::Shrink', qw(shrink_id));
}

for my $d (@$data) {
  my ($tv, $tr) = @$d;
  ok(shrink_id($tv) eq $tr, "$tv test OK");
}

BEGIN {
  use_ok('Data::ID::URL::Shrink', qw(:encoding));
}

for my $d (@$data) {
  my ($tv, $tr) = @$d;
  my $id = shrink_id($tv);
  my $num = stretch_id($id);
  ok($id eq $tr && $num eq $tv, "There and back again OK: $tv <=> $tr");
}

BEGIN {
  use_ok('Data::ID::URL::Shrink', qw(:all));
}

ok(length random_id(8) == 8, 'got 8-character id');
ok(length random_id == 11, 'got 11-character id');

for(3 .. 32) {
  my $n = $_;
  ok(length random_id($n) == $n, "random_id($n) gives $n-character id");
}

# FAIL TESTS
for(0 .. 2) {
  my $n = $_;
  is(random_id($n), undef, "random_id($n) returns undef");
}

is(random_id(-1), undef, "random_id(-1) returns undef");

is(shrink_id('asdf'), undef, "shrink_id('asdf') returns undef");
is(shrink_id(-1), undef, "shrink_id(-1) returns undef");
is(stretch_id('Asdf'), undef, "stretch_id('Asdf') returns undef");

done_testing();
