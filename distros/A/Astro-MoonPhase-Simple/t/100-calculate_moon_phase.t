#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.01';

use Test::More;

use FindBin;

use lib ($FindBin::Bin, 'blib/lib');

use Astro::MoonPhase::Simple;

my @tests = (
  {
    'params' => {
	#"name" => "Normandy Landing",
	"date" => "1944-06-06",
	"time" => "05:00:00",
	#"timezone" => "Europe/Paris",
	"location" => {lat=>49.180000, lon=>-0.370000}
    },
    'expected' => {
  "MoonPhase" => "0.47624379092298",
  "MoonIllum%" => "99.4440348933393",
  "MoonAng" => "0.516993100864577",
  "SunDist" => "151812080.505446",
  "MoonAge" => "14.0637595011504",
  "MoonPhase%" => "47.624379092298",
  "MoonIllum" => "0.994440348933393",
  "phases" => {
    "Full moon" => "Tue Jun  6 20:59:37 1944",
    "New Moon" => "Mon May 22 08:14:24 1944",
    "First quarter" => "Tue May 30 02:06:14 1944",
    "Next New Moon" => "Tue Jun 20 19:01:26 1944",
    "Last quarter" => "Tue Jun 13 17:57:49 1944"
  },
  "SunAng" => "0.52535443057273",
  "MoonDist" => "385224.015111506",
  "asString" => "Moon age: 14.0637595011504 days\nMoon phase: 47.6 % of cycle (birth-to-death)\nMoon's illuminated fraction: 99.4 % of full disc\nimportant moon phases around specified date 1944-06-06:\n  New Moon      = Mon May 22 08:14:24 1944\n  First quarter = Tue May 30 02:06:14 1944\n  Full moon     = Tue Jun  6 20:59:37 1944\n  Last quarter  = Tue Jun 13 17:57:49 1944\n  New Moon      = Tue Jun 20 19:01:26 1944\n"
    }
  },
  {
    'params' => {
	#"name" => "US Invasion of Cuba, Bay of Pigs",
	"date" => "1961-04-15",
	"time" => "05:00:00",
	"timezone" => "America/Havana",
	#"location" => {lon=>-81.1376, lat=>22.17927}
    },
    'expected' => {
  "asString" => "Moon age: 0.207041969010797 days\nMoon phase: 0.7 % of cycle (birth-to-death)\nMoon's illuminated fraction: 0.0 % of full disc\nimportant moon phases around specified date 1961-04-15:\n  New Moon      = Thu Mar 16 20:52:17 1961\n  First quarter = Fri Mar 24 04:48:34 1961\n  Full moon     = Sat Apr  1 07:48:56 1961\n  Last quarter  = Sat Apr  8 12:15:43 1961\n  New Moon      = Sat Apr 15 07:39:24 1961\n",
  "MoonDist" => "379303.220266235",
  "SunAng" => "0.531330930943088",
  "phases" => {
    "Full moon" => "Sat Apr  1 07:48:56 1961",
    "Next New Moon" => "Sat Apr 15 07:39:24 1961",
    "Last quarter" => "Sat Apr  8 12:15:43 1961",
    "First quarter" => "Fri Mar 24 04:48:34 1961",
    "New Moon" => "Thu Mar 16 20:52:17 1961"
  },
  "MoonAge" => "0.207041969010797",
  "MoonIllum" => "0.000485067392961225",
  "MoonPhase%" => "0.701110198832639",
  "SunDist" => "150104472.492197",
  "MoonAng" => "0.525063188127456",
  "MoonIllum%" => "0.0485067392961225",
  "MoonPhase" => "0.00701110198832639"
    }
  },
  {
    'params' => {
	#"name" => "Invasion of Libya",
	"date" => "2011-03-19",
	"time" => "05:00:00",
	"timezone" => "Africa/Tripoli",
    },
    'expected' => {
  "asString" => "Moon age: 14.0213525003449 days\nMoon phase: 47.5 % of cycle (birth-to-death)\nMoon's illuminated fraction: 99.4 % of full disc\nimportant moon phases around specified date 2011-03-19:\n  New Moon      = Fri Mar  4 22:47:33 2011\n  First quarter = Sun Mar 13 01:46:01 2011\n  Full moon     = Sat Mar 19 20:10:48 2011\n  Last quarter  = Sat Mar 26 14:08:25 2011\n  New Moon      = Sun Apr  3 17:33:33 2011\n",
  "SunAng" => "0.535497955725337",
  "MoonDist" => "363614.145407531",
  "MoonIllum" => "0.993749330351417",
  "MoonAge" => "14.0213525003449",
  "MoonPhase%" => "47.4807754504436",
  "phases" => {
    "Full moon" => "Sat Mar 19 20:10:48 2011",
    "Last quarter" => "Sat Mar 26 14:08:25 2011",
    "Next New Moon" => "Sun Apr  3 17:33:33 2011",
    "First quarter" => "Sun Mar 13 01:46:01 2011",
    "New Moon" => "Fri Mar  4 22:47:33 2011"
  },
  "MoonPhase" => "0.474807754504436",
  "MoonIllum%" => "99.3749330351417",
  "MoonAng" => "0.547718400440081",
  "SunDist" => "148936421.241741"
    }
  },
  {
    'params' => {
	#"name" => "Invasion of Iraq",
	"date" => "2003-03-19",
	"time" => "05:00:00",
	"timezone" => "Asia/Baghdad",
    },
    'expected' => {
  "MoonIllum%" => "99.4103610150162",
  "MoonPhase" => "0.524466449081286",
  "SunDist" => "148932085.433747",
  "MoonAng" => "0.544972758660398",
  "MoonPhase%" => "52.4466449081286",
  "MoonAge" => "15.4878029842796",
  "MoonIllum" => "0.994103610150162",
  "phases" => {
    "Last quarter" => "Tue Mar 25 03:52:49 2003",
    "Next New Moon" => "Tue Apr  1 22:20:34 2003",
    "New Moon" => "Mon Mar  3 04:37:12 2003",
    "First quarter" => "Tue Mar 11 09:16:32 2003",
    "Full moon" => "Tue Mar 18 12:36:17 2003"
  },
  "SunAng" => "0.535513545491037",
  "MoonDist" => "365446.079524328",
  "asString" => "Moon age: 15.4878029842796 days\nMoon phase: 52.4 % of cycle (birth-to-death)\nMoon's illuminated fraction: 99.4 % of full disc\nimportant moon phases around specified date 2003-03-19:\n  New Moon      = Mon Mar  3 04:37:12 2003\n  First quarter = Tue Mar 11 09:16:32 2003\n  Full moon     = Tue Mar 18 12:36:17 2003\n  Last quarter  = Tue Mar 25 03:52:49 2003\n  New Moon      = Tue Apr  1 22:20:34 2003\n"
    }
  },
  {
    'params' => {
	#"name" => "Scylla and Charybdis",
	"date" => "2021-10-09",
	"time" => "01:00:00",
	"location" => {lon=>38.245833, lat=>15.6325},
    },
    'expected' => {
  "MoonIllum" => "0.0829415987864076",
  "MoonAge" => "2.74601783357238",
  "MoonPhase%" => "9.29889296596434",
  "phases" => {
    "Full moon" => "Wed Oct 20 17:57:41 2021",
    "Last quarter" => "Thu Oct 28 23:06:44 2021",
    "Next New Moon" => "Thu Nov  4 23:15:26 2021",
    "First quarter" => "Wed Oct 13 06:27:35 2021",
    "New Moon" => "Wed Oct  6 14:05:44 2021"
  },
  "MoonPhase" => "0.0929889296596434",
  "MoonIllum%" => "8.29415987864076",
  "SunDist" => "149415040.381477",
  "MoonAng" => "0.546482182923735",
  "asString" => "Moon age: 2.74601783357238 days\nMoon phase: 9.3 % of cycle (birth-to-death)\nMoon's illuminated fraction: 8.3 % of full disc\nimportant moon phases around specified date 2021-10-09:\n  New Moon      = Wed Oct  6 14:05:44 2021\n  First quarter = Wed Oct 13 06:27:35 2021\n  Full moon     = Wed Oct 20 17:57:41 2021\n  Last quarter  = Thu Oct 28 23:06:44 2021\n  New Moon      = Thu Nov  4 23:15:26 2021\n",
  "SunAng" => "0.533782602503564",
  "MoonDist" => "364436.690386654"
}
  },
);

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

my @expected_keys = qw/MoonPhase MoonPhase% MoonIllum MoonIllum% MoonAge MoonDist MoonAng SunDist SunAng phases asString/;
my %expected_keys = map { $_ => 1 } @expected_keys;
for my $atest (@tests){
	my $got = calculate_moon_phase($atest->{'params'});
	ok(defined $got, 'calculate_moon_phase()'.": called and got defined result.");
	is(ref($got), 'HASH', 'calculate_moon_phase()'.": called and got defined result which is a HASH.");
	for my $ak (@expected_keys){
		ok(exists($got->{$ak}), 'calculate_moon_phase()'.": expected key '$ak' is in the returned result.");
		ok(defined($got->{$ak}), 'calculate_moon_phase()'.": expected key '$ak' is in the returned result and it is defined.");
	}
	for my $ak (sort keys %$got){
		ok(exists($expected_keys{$ak}), 'calculate_moon_phase()'.": returned key '$ak' is in the expected keys.");
		ok(defined($expected_keys{$ak}), 'calculate_moon_phase()'.": returned key '$ak' is in the expected keys and it is defined.");
	}
	is_deeply($got, $atest->{'expected'}, 'calculate_moon_phase()'.": returned result is as expected numerically");
}

done_testing;
