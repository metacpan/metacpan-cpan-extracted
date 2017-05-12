# -*- perl -*-

# t/016_case.t - check case insensitive date formats

use strict;
use warnings;
no warnings qw(once);

use Test::More tests => 1 + 1 + 12 * 3;
use Test::NoWarnings;

use DateTime::Format::CLDR;

my %months = (
  Jan => 1, Feb => 2, Mar => 3, Apr => 4,
  May => 5, Jun => 6, Jul => 7, Aug => 8,
  Sep => 9, Oct => 10, Nov => 11, Dec => 12,
);

my $cldr = DateTime::Format::CLDR->new(
  pattern => "MMM",
  locale => "en_US",
);

ok($cldr, "Got CLDR object");

while (my ($name, $num) = each %months) {
  is($cldr->parse_datetime($name)->month, $num, "$name regular");
  is($cldr->parse_datetime(uc $name)->month, $num, "$name uppercase");
  is($cldr->parse_datetime(lc $name)->month, $num, "$name lowercase");
}