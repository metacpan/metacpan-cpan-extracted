#!/usr/bin/perl -w

use strict;
use Test;
use Business::CINS;

BEGIN { plan tests => 12 }

# Check some really bad CINSes
my @values = ('A392690!','T', 'B03523A$','2',
              'C15725A&','3', 'D^1944AA','7');
while (@values) {
  my ($v, $expected) = splice @values, 0, 2;
  my $cn = Business::CINS->new($v.$expected, 1);
  ok(!defined($cn->check_digit()));
  ok($Business::CINS::ERROR, qr/^Invalid char/,
     "  Did not get the expected error. Got $Business::CINS::ERROR\n");
  ok($cn->error, qr/^Character.*must be/,
     "  Did not get the expected error. Got ".$cn->error);
}

__END__
