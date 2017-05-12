#!/usr/bin/perl -w

use strict;
use Test;
use Business::CINS;

BEGIN { plan tests => 24 }

# Check some fixed income securities
my @values = ('P4052KAB','3', 'Y8578HAC','4', 'G49116AA','7',
              'Y68851AJ','6', 'M60170AB','9', 'U25468AJ','5',
              'G3528RAA','8', 'W10020AH','3'
              );
while (@values) {
  my ($v, $expected) = splice @values, 0, 2;
  my $cn = Business::CINS->new($v.$expected, 1);
  my $c = $cn->check_digit();
  ok($c, $expected, "check_digit of $v expected $expected; got $c\n");
  ok($cn->is_valid());
  $cn->cins("$v".(9-$expected));
  ok(!$cn->is_valid());
}

__END__
