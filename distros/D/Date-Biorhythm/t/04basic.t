use Test::More;

use strict;
use warnings;
use Date::Biorhythm;

my $db;

my @specifications = (
  # Date::Biorhythm requires a birthday for instantiation.
  sub {
    my $expectation = "Date::Biorhythm should raise an exception if a birthday is not given.";
    eval {
      $db = Date::Biorhythm->new();
    };
    ok($@, $expectation);
  },
  sub {
    my $expectation = "Date::Biorhythm takes Date::Calc::Object instances for dates.";
    $db = Date::Biorhythm->new(birthday => Date::Calc::Object->today - 1);
    ok($db, $expectation);
  },
# sub {
#   my $expectation = "If I give it a string that Date::Calc::Parse_Date() can understand, that's OK, too.";
#   $db = Date::Biorhythm->new(birthday => '1990-10-10');
#   ok($db, $expectation);
# }
);

plan tests => scalar(@specifications);

foreach (@specifications) {
  $_->();
}
