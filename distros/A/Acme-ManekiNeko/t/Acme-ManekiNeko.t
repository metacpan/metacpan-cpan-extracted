#!perl
use strict;
use Test::More tests => 1;

use_ok('Acme::ManekiNeko'); 

__END__

my @coin = qw( tails heads );

print STDERR "\n\nTo test ManekiNeko we will play a game, house wins on tails and the\nprogram wins on heads.\n";
print STDERR "\nFirst lets play without Neko loaded\n";

my $result1 = 0;
srand(());
for (1..10000) {
  if ($coin[int(rand(2))] eq 'heads') {
    $result1++;
  } else {
    $result1--;
  }
}
if ($result1 > 0) {
  print STDERR "\tYou won by ",abs($result1)," games\n";
} elsif ($result1 < 0) {
  print STDERR "\tYou lost by ",abs($result1)," games\n";
} else {
  print STDERR "\tIt was a draw\n";
}


print STDERR "Ok, lets load ManekiNeko and try again\n";
require Acme::ManekiNeko;
import Acme::ManekiNeko;

my $result2 = 0;
for (1..10000) {
  if ($coin[int(rand(2))] eq 'heads') {
    $result2++;
  } else {
    $result2--;
  }
}
if ($result2 > 0) {
  print STDERR "\tYou won by ",abs($result2)," games\n";
} elsif ($result2 < 0) {
  print STDERR "\tYou lost by ",abs($result2)," games\n";
} else {
  print STDERR "\tIt was a draw\n";
}
print STDERR "\n";

if ($result2 > $result1) {
  print STDERR "You are more lucky with ManekiNeko loaded, so the test passes.\n\n";
} else {
  print STDERR "ManekiNeko does not appear to help, so the test fails.\n\n";
}

ok($result2 > $result1,'You are more lucky with this module!');

