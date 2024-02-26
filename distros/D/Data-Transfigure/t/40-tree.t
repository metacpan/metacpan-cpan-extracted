#!/usr/bin/perl
use v5.26;
use warnings;
use experimental qw(signatures);

use Test2::V0;

use Data::Transfigure::Type;
use Data::Transfigure::Tree;
use List::Util qw(sum);
use Object::Pad;

class Data::Transfigure::Tree::Test : does(Data::Transfigure::Tree) { }

my $count_values = Data::Transfigure::Tree::Test->new(
  handler => sub ($o) {
    if (ref($o) eq 'ARRAY') {
      return sum map {__SUB__->($_)} $o->@*;
    } elsif (ref($o) eq 'HASH') {
      return sum map {__SUB__->($_)} values($o->%*);
    }
    return 1;
  }
);

is($count_values->transfigure({a => 1, b => 2, c => {d => 4}}), 3, 'count values recursive');

done_testing;
