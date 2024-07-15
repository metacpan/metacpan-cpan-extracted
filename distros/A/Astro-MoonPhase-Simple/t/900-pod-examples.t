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
	'date' => '1974-07-14',
	'timezone' => 'Asia/Nicosia',
    },
    'expected' => {
  "MoonAge" => "23.3844472122507",
  "asString" => "Moon age: 23.3844472122507 days\nMoon phase: 79.2 % of cycle (birth-to-death)\nMoon's illuminated fraction: 37.0 % of full disc\nimportant moon phases around specified date 1974-07-14:\n  New Moon      = Thu Jun 20 06:55:39 1974\n  First quarter = Wed Jun 26 21:20:07 1974\n  Full moon     = Thu Jul  4 14:40:23 1974\n  Last quarter  = Fri Jul 12 17:28:59 1974\n  New Moon      = Fri Jul 19 14:06:16 1974\n",
  "SunDist" => "152070982.923484",
  "MoonPhase%" => "79.1872030241244",
  "MoonIllum%" => "36.9967400246233",
  "MoonAng" => "0.519473222387291",
  "phases" => {
    "Next New Moon" => "Fri Jul 19 14:06:16 1974",
    "First quarter" => "Wed Jun 26 21:20:07 1974",
    "Full moon" => "Thu Jul  4 14:40:23 1974",
    "New Moon" => "Thu Jun 20 06:55:39 1974",
    "Last quarter" => "Fri Jul 12 17:28:59 1974"
  },
  "SunAng" => "0.524460009232199",
  "MoonDist" => "383384.839712717",
  "MoonPhase" => "0.791872030241244",
  "MoonIllum" => "0.369967400246233"
    },
  },
  {
    'params' => {
	'date' => '1974-07-14',
	'time' => '04:00:00',
	'location' => {lat=>49.180000, lon=>-0.370000}
    },
    'expected' => {
  "MoonAng" => "0.520864887238229",
  "SunAng" => "0.524464640205641",
  "MoonPhase" => "0.79895266077578",
  "MoonDist" => "382360.498815714",
  "MoonIllum" => "0.348624099504418",
  "phases" => {
    "New Moon" => "Thu Jun 20 06:55:39 1974",
    "Last quarter" => "Fri Jul 12 17:28:59 1974",
    "Full moon" => "Thu Jul  4 14:40:23 1974",
    "First quarter" => "Wed Jun 26 21:20:07 1974",
    "Next New Moon" => "Fri Jul 19 14:06:16 1974"
  },
  "SunDist" => "152069640.151009",
  "MoonAge" => "23.5935424001611",
  "asString" => "Moon age: 23.5935424001611 days\nMoon phase: 79.9 % of cycle (birth-to-death)\nMoon's illuminated fraction: 34.9 % of full disc\nimportant moon phases around specified date 1974-07-14:\n  New Moon      = Thu Jun 20 06:55:39 1974\n  First quarter = Wed Jun 26 21:20:07 1974\n  Full moon     = Thu Jul  4 14:40:23 1974\n  Last quarter  = Fri Jul 12 17:28:59 1974\n  New Moon      = Fri Jul 19 14:06:16 1974\n",
  "MoonPhase%" => "79.895266077578",
  "MoonIllum%" => "34.8624099504418"
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
