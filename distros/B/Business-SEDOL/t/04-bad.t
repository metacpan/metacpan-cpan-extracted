#!/usr/bin/perl -w

use strict;
use Test;
use Business::SEDOL;

BEGIN { plan tests => 48 }

# Bad length

foreach (qw/012345 012545 010100 217100/) {
  my $sdl = Business::SEDOL->new($_);
  ok($sdl->is_valid, '', "  Expected an error, but SEDOL $_ seems to be valid.");
  ok($Business::SEDOL::ERROR, qr/^SEDOLs .* 7 characters/,
     "  Got an unexpected error: $Business::SEDOL::ERROR.");
  ok($sdl->error, qr/^SEDOLs .* 7 characters/,
     "  Got an unexpected error: ".$sdl->error);
}

# Non-numeric
foreach (qw/O123457 012.453 010T000 2!71001 30201e5 4-68631 548g182/) {
  my $sdl = Business::SEDOL->new($_);
  ok($sdl->is_valid, '', "  Expected an error, but SEDOL $_ seems to be valid.");
  ok($Business::SEDOL::ERROR);
  ok($sdl->error);
}

# Bad check digit
foreach (qw/3020134 4668630 5484189 6597458 7060859/) {
  my $sdl = Business::SEDOL->new($_);
  ok($sdl->is_valid, '', "  Expected an error, but SEDOL $_ seems to be valid.");
  ok($Business::SEDOL::ERROR, qr/^Check digit (?:in|not )correct/,
     "  Got an unexpected error: $Business::SEDOL::ERROR.");
  ok($sdl->error, qr/^Check digit (?:in|not )correct/,
     "  Got an unexpected error: ".$sdl->error);
}

__END__
