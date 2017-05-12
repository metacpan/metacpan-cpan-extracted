#!/usr/bin/perl -w

use strict;
use Test;
use Business::CUSIP;

BEGIN { plan tests => 30 }

# Check some fixed income securities
my @values = ('392690QT','3', '035231AH','2', '157125AA','3', '119424AA','7',
              '125144AC','9', '022069AG','3', '016783A@','1', '05435#AB','6',
              '07790*BU','2', '989349B*','5');
while (@values) {
  my ($v, $expected) = splice @values, 0, 2;
  my $csp = Business::CUSIP->new($v.$expected, 1);
  my $c = $csp->check_digit();
  ok($c, $expected, "check_digit of $v expected $expected; got $c\n");
  ok($csp->is_valid());
  $csp->cusip("$v".(9-$expected));
  ok(!$csp->is_valid());
}

__END__
