use v5.26;
use warnings;

use Test2::V0;

use DateTime::Schedule;
use DateTime::Schedule::Weekly;

my $dts;

$dts = DateTime::Schedule->new();

$dts = DateTime::Schedule->new(portion => 0.5);

is($dts->portion, 0.5, 'check parameter forwarding (portion)');

$dts = DateTime::Schedule::Weekly->new();

is($dts->sunday,    bool(1));
is($dts->monday,    bool(1));
is($dts->tuesday,   bool(1));
is($dts->wednesday, bool(1));
is($dts->thursday,  bool(1));
is($dts->friday,    bool(1));
is($dts->saturday,  bool(1));

$dts = DateTime::Schedule::Weekly->new(
  sunday    => 1,
  monday    => 0,
  tuesday   => 0,
  wednesday => 0,
  thursday  => 0,
  friday    => 0,
  saturday  => 0
);

is($dts->sunday,    bool(1));
is($dts->monday,    bool(0));
is($dts->tuesday,   bool(0));
is($dts->wednesday, bool(0));
is($dts->thursday,  bool(0));
is($dts->friday,    bool(0));
is($dts->saturday,  bool(0));

ok(
  dies {
    DateTime::Schedule::Weekly->new(
      sunday    => 0,
      monday    => 0,
      tuesday   => 0,
      wednesday => 0,
      thursday  => 0,
      friday    => 0,
      saturday  => 0
    )
  },
  'must have at least one day scheduled'
);

my $w = DateTime::Schedule::Weekly->weekdays(exclude => [DateTime->now], portion => 0.5);

is($w->sunday,    bool(0));
is($w->monday,    bool(1));
is($w->tuesday,   bool(1));
is($w->wednesday, bool(1));
is($w->thursday,  bool(1));
is($w->friday,    bool(1));
is($w->saturday,  bool(0));
is($w->portion,   0.5, 'check weekdays parameter forwarding (portion)');

$w = DateTime::Schedule::Weekly->weekends(exclude => [DateTime->now, DateTime->now->subtract(days => 5)], portion => 0.75);

is($w->sunday,    bool(1));
is($w->monday,    bool(0));
is($w->tuesday,   bool(0));
is($w->wednesday, bool(0));
is($w->thursday,  bool(0));
is($w->friday,    bool(0));
is($w->saturday,  bool(1));
is($w->portion,   0.75, 'check weekends parameter forwarding (portion)');

done_testing;
