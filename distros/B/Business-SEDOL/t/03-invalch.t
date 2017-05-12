#!/usr/bin/perl -w

use strict;
use Test;
use Business::SEDOL;

BEGIN { plan tests => 27 }

my $sdl;
# Check some really bad SEDOLS
for (qw/1B12457 012.453 B1OT000 2!71001 30201e5 4-68631 A48G18Z/) {
  $sdl = Business::SEDOL->new($_);
  ok(!defined($sdl->check_digit()));
  ok($Business::SEDOL::ERROR);
  ok($sdl->error);
}
# Check new-style SEDOL problems
$sdl = Business::SEDOL->new('ABCDEF6');
ok(!defined($sdl->check_digit()));
ok($Business::SEDOL::ERROR, qr/must have alphabetic first/,
   "  Did not get the expected error. Got $Business::SEDOL::ERROR\n");
$sdl = Business::SEDOL->new('B2E4567');
ok(!defined($sdl->check_digit()));
ok($Business::SEDOL::ERROR, qr/must have alpha.*2/,
   "  Did not get the expected error. Got $Business::SEDOL::ERROR\n");
$sdl = Business::SEDOL->new('B23456A');
ok(!defined($sdl->check_digit()));
ok($Business::SEDOL::ERROR, qr/checkdigit.*must be num/,
   "  Did not get the expected error. Got $Business::SEDOL::ERROR\n");

__END__
