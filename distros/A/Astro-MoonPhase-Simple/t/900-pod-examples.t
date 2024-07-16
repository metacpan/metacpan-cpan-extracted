#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.01';

use Test::More;

use FindBin;

use lib ($FindBin::Bin, 'blib/lib');

use Astro::MoonPhase::Simple;

my $VERBOSITY = 10;

my @tests = (
  {
    'params' => {
	'verbosity' => $VERBOSITY,
	'date' => '1974-07-14',
	'timezone' => 'Asia/Nicosia',
    },
    'expected' => {
  "MoonDist" => "382975.037274059",
  "phases" => {
    "First quarter" => "Wed Jun 26 21:20:07 1974",
    "New Moon" => "Thu Jun 20 06:55:39 1974",
    "Last quarter" => "Fri Jul 12 17:28:59 1974",
    "Full moon" => "Thu Jul  4 14:40:23 1974",
    "Next New Moon" => "Fri Jul 19 14:06:16 1974"
  },
  "MoonAge" => "23.4679002028918",
  "SunAng" => "0.524461848994832",
  "MoonPhase" => "0.794698014902281",
  "MoonAng" => "0.520029084708937",
  "SunDist" => "152070449.472838",
  "MoonIllum%" => "36.1415741763651",
  "asString" => "Moon age: 23.4679002028918 days\nMoon phase: 79.5 % of cycle (birth-to-death)\nMoon's illuminated fraction: 36.1 % of full disc\nimportant moon phases around specified date 1974-07-14:\n  New Moon      = Thu Jun 20 06:55:39 1974\n  First quarter = Wed Jun 26 21:20:07 1974\n  Full moon     = Thu Jul  4 14:40:23 1974\n  Last quarter  = Fri Jul 12 17:28:59 1974\n  New Moon      = Fri Jul 19 14:06:16 1974\n",
  "MoonIllum" => "0.361415741763651",
  "MoonPhase%" => "79.4698014902281"
    },
  },
  {
    'params' => {
	'verbosity' => $VERBOSITY,
	'date' => '1974-07-14',
	'time' => '04:00:00',
	'location' => {lat=>49.180000, lon=>-0.370000}
    },
    'expected' => {
  "asString" => "Moon age: 23.6355548766888 days\nMoon phase: 80.0 % of cycle (birth-to-death)\nMoon's illuminated fraction: 34.4 % of full disc\nimportant moon phases around specified date 1974-07-14:\n  New Moon      = Thu Jun 20 06:55:39 1974\n  First quarter = Wed Jun 26 21:20:07 1974\n  Full moon     = Thu Jul  4 14:40:23 1974\n  Last quarter  = Fri Jul 12 17:28:59 1974\n  New Moon      = Fri Jul 19 14:06:16 1974\n",
  "MoonIllum%" => "34.4370488526887",
  "SunDist" => "152069367.893738",
  "MoonAng" => "0.521143961017668",
  "MoonPhase" => "0.800375337342878",
  "MoonPhase%" => "80.0375337342878",
  "MoonIllum" => "0.344370488526887",
  "phases" => {
    "Next New Moon" => "Fri Jul 19 14:06:16 1974",
    "Full moon" => "Thu Jul  4 14:40:23 1974",
    "Last quarter" => "Fri Jul 12 17:28:59 1974",
    "New Moon" => "Thu Jun 20 06:55:39 1974",
    "First quarter" => "Wed Jun 26 21:20:07 1974"
  },
  "MoonDist" => "382155.743896739",
  "SunAng" => "0.524465579180487",
  "MoonAge" => "23.6355548766888"
    }
  },
  {
    'params' => {
	'verbosity' => $VERBOSITY,
	'date' => '1974-07-14',
	'time' => '04:00:00',
	'location' => 'Nicosia',
    },
    'expected' => {
  "MoonPhase%" => "80.0375337342878",
  "MoonIllum" => "0.344370488526887",
  "asString" => "Moon age: 23.6355548766888 days\nMoon phase: 80.0 % of cycle (birth-to-death)\nMoon's illuminated fraction: 34.4 % of full disc\nimportant moon phases around specified date 1974-07-14:\n  New Moon      = Thu Jun 20 06:55:39 1974\n  First quarter = Wed Jun 26 21:20:07 1974\n  Full moon     = Thu Jul  4 14:40:23 1974\n  Last quarter  = Fri Jul 12 17:28:59 1974\n  New Moon      = Fri Jul 19 14:06:16 1974\n",
  "MoonIllum%" => "34.4370488526887",
  "SunDist" => "152069367.893738",
  "MoonAng" => "0.521143961017668",
  "MoonPhase" => "0.800375337342878",
  "SunAng" => "0.524465579180487",
  "MoonAge" => "23.6355548766888",
  "phases" => {
    "Last quarter" => "Fri Jul 12 17:28:59 1974",
    "New Moon" => "Thu Jun 20 06:55:39 1974",
    "First quarter" => "Wed Jun 26 21:20:07 1974",
    "Next New Moon" => "Fri Jul 19 14:06:16 1974",
    "Full moon" => "Thu Jul  4 14:40:23 1974"
  },
  "MoonDist" => "382155.743896739"
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
