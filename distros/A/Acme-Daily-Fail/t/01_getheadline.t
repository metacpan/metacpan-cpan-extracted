use strict;
use warnings;
use Test::More tests => 10;

use Acme::Daily::Fail qw(get_headline);

for (1..10) {
  my $headline = get_headline();
  diag("$headline\n");
  ok($headline,'Got a headline');
}
