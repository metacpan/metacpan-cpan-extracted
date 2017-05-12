#!/usr/bin/perl -w

use strict;
use Test;
use Business::CUSIP;

BEGIN { plan tests => 12 }

# Check some really bad CUSIPS
my @values = ('392690!T','3', '035231A$','2', '157125A&','3', '^19424AA','7');
while (@values) {
  my ($v, $expected) = splice @values, 0, 2;
  my $csp = Business::CUSIP->new($v.$expected, 1);
  ok(!defined($csp->check_digit()));
  ok($Business::CUSIP::ERROR, qr/^Invalid char/,
     "  Did not get the expected error. Got $Business::CUSIP::ERROR\n");
  ok($csp->error, qr/^Character.*must be/,
     "  Did not get expected error. Got ".$csp->error);
}

__END__
