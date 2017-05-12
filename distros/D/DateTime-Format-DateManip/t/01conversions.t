use strict;

use Test::More;

use DateTime::Format::DateManip;
use DateTime;
use Date::Manip;


my $dfdm = "DateTime::Format::DateManip";

## Set the timezone for Date::Manip and DateTime
my $dm_tz = "EST";
my $dt_tz = "US/Eastern";

# Setup Date::Manip manually so we can force the TZ to beat a config
# file setting
Date_Init("TZ=$dm_tz");

## Date::Manip to DateTime
my @dm_to_dt_tests = 
    (["March 23, 2003" =>
      DateTime->new(year => 2003, month => 3, day => 23, time_zone => $dt_tz) ],
     ["March 23, 2003 12:00 EST" =>
      DateTime->new(year => 2003, month => 3, day => 23,
		    hour => 12,   time_zone => $dt_tz) ],
     );

## DateTime to Date::Manip
# Redefine the DT timezone to make sure we get the conversion right
$dt_tz = "US/Pacific";
my @dt_to_dm_tests = 
    ([DateTime->new(year => 2003, month => 3, day => 23, time_zone => $dt_tz) =>
      '2003032303:00:00'],
     [DateTime->new(year => 2003, month => 3, day => 23,
		    hour => 12,   time_zone => $dt_tz) =>
      '2003032315:00:00'],
     );

## Date::Manip Delta to DateTime::Duration
my $dur1 = DateTime::Duration->new(years => 3, months => 2);
$dur1->subtract(hours => 3, minutes => 57, seconds => 2);

my @dm_to_dt_dur_tests =
    (["3 years 2 months -4 hours +3mn -2 second",
      $dur1],
     );

## DateTime::Duration to Date::Manip Delta
my @dt_to_dm_dur_tests =
    ([$dur1,
      ParseDateDelta("3 years 2 months -4 hours +3mn -2 second")],
     );

# Work out how many tests there are
plan tests => @dm_to_dt_tests     + @dt_to_dm_tests     +
              @dm_to_dt_dur_tests + @dt_to_dm_dur_tests ;

foreach my $t (@dm_to_dt_tests) {
    my ($f, $dt) = @$t;

    my $res = $dfdm->parse_datetime($f);

    my $d1 = $dt->strftime("%FT%T.%9N %Z\n");
    my $d2 = defined $res ? $res->strftime("%FT%T.%9N %Z\n") : 'undef';

    is($d2, $d1, "Parse Date '$f'");
}

foreach my $t (@dt_to_dm_tests) {
    my ($dt, $dm) = @$t;
    my $res = $dfdm->format_datetime($dt);
    is($res, $dm, "Format Date '".$dt->datetime."'");
}

foreach my $t (@dm_to_dt_dur_tests) {
    my ($dm, $dt) = @$t;
    my $res = $dfdm->parse_duration($dm);

    my $d1 = format_dur($dt);
    my $d2 = format_dur($res);

    is($d2, $d1, "Parse Duration '$d1'");
}

foreach my $t (@dt_to_dm_dur_tests) {
    my ($dt, $dm) = @$t;

    my $res = $dfdm->format_duration($dt);
    my $d2 = format_dur($dt);

    is($res, $dm, "Format Duration '$d2'");
}


sub format_dur {
    my $dur = shift;
    return undef unless defined $dur;

    my %deltas = $dur->deltas();
    my @args = ();
    foreach my $k (qw( months days minutes seconds )) {
	push @args, "$k=$deltas{$k}";
    }

    return join ":", @args;
}
