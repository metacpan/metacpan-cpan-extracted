#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.03';

use Test::More;

use FindBin;

use lib ($FindBin::Bin, 'blib/lib');

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;
use Config;

use Astro::MoonPhase::Simple;

my $VERBOSITY = 10;

###### WARNING These expected values expect
# that $dt->set_time_zone('UTC'); is used
# in lib/Astro/MoonPhase/Simple.pm
############################################

###### WARNING is_deeply()
# complains when it compares reals differing
# to the very last least-significant digits.
# (because we ask it to compare, e.g. Moon angle)
# the expected results (e.g. moon angle)
# were produced on my machine and can differ
# for other machines or for Perls compiled
# differently (e.g. see -Duselongdouble and
# the bug reported https://rt.cpan.org/Ticket/Display.html?id=154401)
# Moreover, in the expected results there is an 'asString'
# which contains lots of those real numbers all mixed up
# in a string.
# This can not be fixed even with the most elaborate is_deeply()
# therefore AT THE MOMENT I will check if perl was compiled
# with -Duselongdouble and if yes I will not run the is_deeply() test
# and wait for more reports.
############################################

my @tests = (
  {
    'params' => {
	"verbosity" => $VERBOSITY,
	#"name" => "Normandy Landing",
	"date" => "1944-06-06",
	"time" => "05:00:00",
	#"timezone" => "Europe/Paris",
	"location" => {lat=>49.180000, lon=>-0.370000}
    },
    'expected' => {
  "SunAng" => "0.525348747757601",
  "MoonIllum%" => "99.5706274169997",
  "MoonAng" => "0.517536236645276",
  "MoonPhase" => "0.479127303280321",
  "phases" => {
    "First quarter" => "Tue May 30 02:06:14 1944",
    "Next New Moon" => "Tue Jun 20 19:01:26 1944",
    "New Moon" => "Mon May 22 08:14:24 1944",
    "Full moon" => "Tue Jun 06 20:59:37 1944",
    "Last quarter" => "Tue Jun 13 17:57:49 1944"
  },
  "MoonDist" => "384819.736277722",
  "SunDist" => "151813722.69074",
  "MoonPhase%" => "47.9127303280321",
  "MoonAge" => "14.1489113185288",
  "asString" => "Moon age: 14.1489113185288 days\nMoon phase: 47.9 % of cycle (birth-to-death)\nMoon's illuminated fraction: 99.6 % of full disc\nimportant moon phases around specified date 1944-06-06:\n  New Moon      = Mon May 22 08:14:24 1944\n  First quarter = Tue May 30 02:06:14 1944\n  Full moon     = Tue Jun 06 20:59:37 1944\n  Last quarter  = Tue Jun 13 17:57:49 1944\n  Next New Moon = Tue Jun 20 19:01:26 1944\n",
  "MoonIllum" => "0.995706274169997"
    }
  },
  {
    'params' => {
	"verbosity" => $VERBOSITY,
	#"name" => "US Invasion of Cuba, Bay of Pigs",
	"date" => "1961-04-15",
	"time" => "05:00:00",
	"timezone" => "America/Havana",
	#"location" => {lon=>-81.1376, lat=>22.17927}
    },
    'expected' => {
  "MoonDist" => "378313.157496339",
  "SunDist" => "150095720.635989",
  "MoonPhase%" => "99.9544805580284",
  "MoonAge" => "29.5171465208219",
  "asString" => "Moon age: 29.5171465208219 days\nMoon phase: 100.0 % of cycle (birth-to-death)\nMoon's illuminated fraction: 0.0 % of full disc\nimportant moon phases around specified date 1961-04-15:\n  New Moon      = Thu Mar 16 13:52:17 1961\n  First quarter = Thu Mar 23 21:48:34 1961\n  Full moon     = Sat Apr 01 00:48:56 1961\n  Last quarter  = Sat Apr 08 05:15:43 1961\n  Next New Moon = Sat Apr 15 00:39:24 1961\n",
  "MoonIllum" => "2.0449999797445e-06",
  "SunAng" => "0.531361912052253",
  "MoonIllum%" => "0.00020449999797445",
  "MoonAng" => "0.526437302413748",
  "MoonPhase" => "0.999544805580283",
  "phases" => {
    "First quarter" => "Thu Mar 23 21:48:34 1961",
    "Next New Moon" => "Sat Apr 15 00:39:24 1961",
    "Last quarter" => "Sat Apr 08 05:15:43 1961",
    "New Moon" => "Thu Mar 16 13:52:17 1961",
    "Full moon" => "Sat Apr 01 00:48:56 1961"
  }
    }
  },
  {
    'params' => {
	"verbosity" => $VERBOSITY,
	#"name" => "Invasion of Libya",
	"date" => "2011-03-19",
	"time" => "05:00:00",
	"timezone" => "Africa/Tripoli",
    },
    'expected' => {
  "MoonAge" => "14.1189471424598",
  "MoonPhase%" => "47.8112620627237",
  "SunDist" => "148939894.674424",
  "MoonDist" => "363544.391463487",
  "asString" => "Moon age: 14.1189471424598 days\nMoon phase: 47.8 % of cycle (birth-to-death)\nMoon's illuminated fraction: 99.5 % of full disc\nimportant moon phases around specified date 2011-03-19:\n  New Moon      = Fri Mar 04 22:47:33 2011\n  First quarter = Sun Mar 13 01:46:01 2011\n  Full moon     = Sat Mar 19 20:10:48 2011\n  Last quarter  = Sat Mar 26 14:08:25 2011\n  Next New Moon = Sun Apr 03 16:33:33 2011\n",
  "MoonIllum" => "0.995279340183898",
  "MoonIllum%" => "99.5279340183898",
  "SunAng" => "0.535485467358099",
  "phases" => {
    "First quarter" => "Sun Mar 13 01:46:01 2011",
    "Next New Moon" => "Sun Apr 03 16:33:33 2011",
    "Last quarter" => "Sat Mar 26 14:08:25 2011",
    "New Moon" => "Fri Mar 04 22:47:33 2011",
    "Full moon" => "Sat Mar 19 20:10:48 2011"
  },
  "MoonAng" => "0.547823492196558",
  "MoonPhase" => "0.478112620627237"
    }
  },
  {
    'params' => {
	"verbosity" => $VERBOSITY,
	#"name" => "Invasion of Iraq",
	"date" => "2003-03-19",
	"time" => "05:00:00",
	"timezone" => "Asia/Baghdad",
    },
    'expected' => {
  "asString" => "Moon age: 15.6317929602378 days\nMoon phase: 52.9 % of cycle (birth-to-death)\nMoon's illuminated fraction: 99.2 % of full disc\nimportant moon phases around specified date 2003-03-19:\n  New Moon      = Mon Mar 03 05:37:12 2003\n  First quarter = Tue Mar 11 10:16:32 2003\n  Full moon     = Tue Mar 18 13:36:17 2003\n  Last quarter  = Tue Mar 25 04:52:49 2003\n  Next New Moon = Tue Apr 01 23:20:34 2003\n",
  "MoonIllum" => "0.991526539695417",
  "MoonAge" => "15.6317929602378",
  "MoonPhase%" => "52.9342409310813",
  "SunDist" => "148937293.646831",
  "MoonDist" => "365174.311358275",
  "phases" => {
    "Last quarter" => "Tue Mar 25 04:52:49 2003",
    "Full moon" => "Tue Mar 18 13:36:17 2003",
    "New Moon" => "Mon Mar 03 05:37:12 2003",
    "Next New Moon" => "Tue Apr 01 23:20:34 2003",
    "First quarter" => "Tue Mar 11 10:16:32 2003"
  },
  "MoonPhase" => "0.529342409310813",
  "MoonAng" => "0.545378335511132",
  "MoonIllum%" => "99.1526539695417",
  "SunAng" => "0.535494819028471"
    }
  },
  {
    'params' => {
	"verbosity" => $VERBOSITY,
	#"name" => "Scylla and Charybdis",
	"date" => "2021-10-09",
	"time" => "01:00:00",
	"location" => {lon=>38.245833, lat=>15.6325},
    },
    'expected' => {
  "MoonDist" => "364241.020839397",
  "SunDist" => "149409670.621389",
  "MoonPhase%" => "9.77704093417059",
  "MoonAge" => "2.88721774334515",
  "asString" => "Moon age: 2.88721774334515 days\nMoon phase: 9.8 % of cycle (birth-to-death)\nMoon's illuminated fraction: 9.1 % of full disc\nimportant moon phases around specified date 2021-10-09:\n  New Moon      = Wed Oct 06 14:05:44 2021\n  First quarter = Wed Oct 13 06:27:35 2021\n  Full moon     = Wed Oct 20 17:57:41 2021\n  Last quarter  = Thu Oct 28 23:06:44 2021\n  Next New Moon = Fri Nov 05 00:15:26 2021\n",
  "MoonIllum" => "0.0914142076550022",
  "SunAng" => "0.533801786566436",
  "MoonIllum%" => "9.14142076550022",
  "MoonAng" => "0.546775752058454",
  "MoonPhase" => "0.0977704093417059",
  "phases" => {
    "Last quarter" => "Thu Oct 28 23:06:44 2021",
    "New Moon" => "Wed Oct 06 14:05:44 2021",
    "Full moon" => "Wed Oct 20 17:57:41 2021",
    "First quarter" => "Wed Oct 13 06:27:35 2021",
    "Next New Moon" => "Fri Nov 05 00:15:26 2021"
  }
    },
  },
  {
    'params' => {
	"verbosity" => $VERBOSITY,
	#"name" => "London",
	"date" => "2021-10-09",
	"time" => "01:00:00",
	"location" => 'London',
    },
    'expected' => {
  "MoonIllum%" => "9.14142076550022",
  "SunAng" => "0.533801786566436",
  "phases" => {
    "Next New Moon" => "Thu Nov 04 21:15:26 2021",
    "First quarter" => "Wed Oct 13 04:27:35 2021",
    "Full moon" => "Wed Oct 20 15:57:41 2021",
    "New Moon" => "Wed Oct 06 12:05:44 2021",
    "Last quarter" => "Thu Oct 28 21:06:44 2021"
  },
  "MoonAng" => "0.546775752058454",
  "MoonPhase" => "0.0977704093417059",
  "MoonAge" => "2.88721774334515",
  "MoonPhase%" => "9.77704093417059",
  "SunDist" => "149409670.621389",
  "MoonDist" => "364241.020839397",
  "asString" => "Moon age: 2.88721774334515 days\nMoon phase: 9.8 % of cycle (birth-to-death)\nMoon's illuminated fraction: 9.1 % of full disc\nimportant moon phases around specified date 2021-10-09:\n  New Moon      = Wed Oct 06 12:05:44 2021\n  First quarter = Wed Oct 13 04:27:35 2021\n  Full moon     = Wed Oct 20 15:57:41 2021\n  Last quarter  = Thu Oct 28 21:06:44 2021\n  Next New Moon = Thu Nov 04 21:15:26 2021\n",
  "MoonIllum" => "0.0914142076550022"
    }
  }
);

#@tests = ($tests[-1]);

my @expected_keys = qw/MoonPhase MoonPhase% MoonIllum MoonIllum% MoonAge MoonDist MoonAng SunDist SunAng phases asString/;
my %expected_keys = map { $_ => 1 } @expected_keys;
for my $atest (@tests){
	my $got = calculate_moon_phase($atest->{'params'});
	ok(defined $got, 'calculate_moon_phase()'.": called and got defined result.") or BAIL_OUT;
	is(ref($got), 'HASH', 'calculate_moon_phase()'.": called and got defined result which is a HASH.") or BAIL_OUT;
	#print perl2dump($got); next;
	for my $ak (@expected_keys){
		ok(exists($got->{$ak}), 'calculate_moon_phase()'.": expected key '$ak' is in the returned result.");
		ok(defined($got->{$ak}), 'calculate_moon_phase()'.": expected key '$ak' is in the returned result and it is defined.");
	}
	for my $ak (sort keys %$got){
		ok(exists($expected_keys{$ak}), 'calculate_moon_phase()'.": returned key '$ak' is in the expected keys.");
		ok(defined($expected_keys{$ak}), 'calculate_moon_phase()'.": returned key '$ak' is in the expected keys and it is defined.");
	}
	is_deeply($got, $atest->{'expected'}, 'calculate_moon_phase()'.": returned result is as expected numerically.") or BAIL_OUT(perl2dump($atest->{'params'})."no, see the parameters above.")
		unless $Config{uselongdouble}
	;
}

done_testing;
