#!/usr/bin/perl -w

use strict;
use Test;
use Business::CINS;

BEGIN { plan tests => 24 }

# Check some non-fixed income CINSs
my @values = ('P4052KAB','3', 'Y0027NAA','9', 'G49331AA','2',
              'Y4420RAA','5', 'G9537LAF','6', 'Y74718AM','2',
              'G6954PAD','2', 'U26054AL','7',
              );

while (@values) {
  my ($v, $expected) = splice @values, 0, 2;
  my $cn = Business::CINS->new($v.$expected);
  my $c = $cn->check_digit();
  ok($c, $expected, "check_digit of $v expected $expected; got $c\n");
  ok($cn->is_valid());
  $cn->cins("$v".(9-$expected));
  ok(!$cn->is_valid());
}

__END__
