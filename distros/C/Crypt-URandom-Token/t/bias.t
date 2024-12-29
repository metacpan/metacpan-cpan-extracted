use strict;
use utf8;
use Test::More;

use_ok("Crypt::URandom::Token" => qw(urandom_token));

my $len       = 2_000_000;
my @alphabet  = ("A" .. "Z", "a" .. "z", "0" .. "9");
my $tolerance = 0.05;

my %values;
foreach my $char (split "", urandom_token($len, \@alphabet)) {
  $values{$char}++;
}

my $avg = $len / @alphabet;
foreach my $char (@alphabet) {
  my $cnt  = $values{$char} || 0;
  my $diff = abs($avg - $cnt);
  cmp_ok($diff, "<", $tolerance * $avg, "$char is within tolerance");
}

done_testing();
