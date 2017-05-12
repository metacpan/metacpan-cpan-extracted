use strict;
use warnings;
use Test::More;
use Test::Fatal;

use lib 't/lib';
use MyDaysInterval;

use DateTime::Moonpig;

# make sure calculated objects preserve the right time zones

for my $test ({ name => "default zone",
                zone_arg => [],
              },
              { name => "New York",
                zone_arg => [time_zone => "America/New_York"],
              },
             ) {
  subtest $test->{name}  => sub {
    my $t = DateTime::Moonpig->new( year   => 1969,
                                    month  =>    4,
                                    day    =>    2,
                                    hour   =>    2,
                                    minute =>   38,
                                    @{$test->{zone_arg}},
                                   );
    my $zone = $test->{zone_arg}[1] || "UTC";
    if ($test->{name} eq "default zone") {
      is($t->time_zone->name, "UTC", "default time zone is UTC");
    }

    my $three_days = MyDaysInterval->new(3);

    for my $time (["+60", $t+60],
                  ["-60", $t-60],
                  ["60+", 60+$t],
                  ["+ threedays",  $t+$three_days,],
                  ["threedays +",  $three_days+$t,],
                  ["- threedays", $t-$three_days],
                 ) {
      is($time->[1]->time_zone->name, $zone,
         "zone of result of $time->[0] computation");
    }
  }
};

done_testing;
