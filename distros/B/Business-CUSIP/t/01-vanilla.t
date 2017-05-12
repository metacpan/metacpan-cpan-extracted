#!/usr/bin/perl -w

use strict;
use Test;
use Business::CUSIP;

BEGIN { plan tests => 42 }

# Check some non-fixed income CUSIPs
my @values = ('100578AA','1', '100599AM','1', '200166AB','2', '200273AD','2',
              '92940*11','8', '00077202','0', '20427#10','9', '38080R10','3',
              '8169951D','6', '83764912','8', '392690QT','3', '035231AH','2',
              '157125AA','3', '90905Q10','9');
while (@values) {
  my ($v, $expected) = splice @values, 0, 2;
  my $csp = Business::CUSIP->new($v.$expected);
  my $c = $csp->check_digit();
  ok($c, $expected, "check_digit of $v expected $expected; got $c\n");
  ok($csp->is_valid());
  $csp->cusip("$v".(9-$expected));
  ok(!$csp->is_valid());
}

__END__
