#!perl


use Test::More tests => 2;
use Acme::Rando;


my $quote   = rando();

ok($quote);

my @quotes = map { rando() } 0 .. 10;
my %quotes = map { $_ => 1 } @quotes;

cmp_ok(scalar keys %quotes, '>', 1);


