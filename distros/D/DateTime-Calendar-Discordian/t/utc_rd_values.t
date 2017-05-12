#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use DateTime;
use DateTime::TimeZone;
use DateTime::Calendar::Discordian;

my @dates = (
    {season => 'Confusion', day => 59, year => 580, rd => -214193},
    {season => 'The Aftermath', day => 47, year => 998, rd => -61387},
    {season => 'Bureaucracy', day => 48, year => 1236, rd => 25469},
    {season => 'Bureaucracy', day => 56, year => 1301, rd => 49217},
    {season => 'Chaos', day => 8, year => 1636, rd => 171307},
    {season => 'Discord', day => 67, year => 1742, rd => 210155},
    {season => 'The Aftermath', day => 22, year => 1860, rd => 253427},
    {season => 'Discord', day => 42, year => 2179, rd => 369740},
    {season => 'Discord', day => 71, year => 2262, rd => 400085},
    {season => 'Discord', day => 9, year => 2356, rd => 434355},
    {season => 'Chaos', day => 69, year => 2406, rd => 452605},
    {season => 'Discord', day => 19, year => 2454, rd => 470160},
    {season => 'Discord', day => 44, year => 2464, rd => 473837},
    {season => 'Confusion', day => 17, year => 2557, rd => 507850},
    {season => 'Chaos', day => 34, year => 2602, rd => 524156},
    {season => 'Discord', day => 26, year => 2658, rd => 544676},
    {season => 'Bureaucracy', day => 43, year => 2719, rd => 567118},
    {season => 'Chaos', day => 64, year => 2726, rd => 569477},
    {season => 'Confusion', day => 15, year => 2814, rd => 601716},
    {season => 'Confusion', day => 35, year => 2846, rd => 613424},
    {season => 'Confusion', day => 59, year => 2882, rd => 626596},
    {season => 'Confusion', day => 24, year => 2934, rd => 645554},
    {season => 'Confusion', day => 68, year => 2985, rd => 664224},
    {season => 'Discord', day => 13, year => 3005, rd => 671401},
    {season => 'Discord', day => 36, year => 3069, rd => 694799},
    {season => 'Bureaucracy', day => 18, year => 3095, rd => 704424},
    {season => 'Bureaucracy', day => 53, year => 3107, rd => 708842},
    {season => 'Discord', day => 36, year => 3109, rd => 709409},
    {season => 'Bureaucracy', day => 61, year => 3109, rd => 709580},
    {season => 'Discord', day => 3, year => 3158, rd => 727274},
    {season => 'Chaos', day => 56, year => 3162, rd => 728714},
    {season => 'The Aftermath', day => 22, year => 3204, rd => 744313},
    {season => 'Confusion', day => 53, year => 3260, rd => 764652},
    {season => 'The Aftermath', day => 73, year => 3177, rd => 734502},
    {season => 'The Aftermath', day => 73, year => 3178, rd => 734868},
);

my $i = 1;
foreach my $d (@dates) {
    is((DateTime::Calendar::Discordian->new
      (season => $d->{season}, day => $d->{day}, year => $d->{year})
      ->utc_rd_values)[0],
      $d->{rd}, "date $i");
    $i++;
}

my $dt =
    DateTime->new(day => 1, month => 1, year => 2012,
        time_zone => 'UTC', hour => 12, minute => 30,
        second => 0, nanosecond => 0);

my $dtcd1 = DateTime::Calendar::Discordian->from_object( object => $dt );

is($dtcd1->strftime("%B %d %Y"), 'Chaos 1 3178', 'utc_rd_values');

my $dtcd2 = DateTime::Calendar::Discordian->from_object( object => $dtcd1 );

is($dtcd2->strftime("%B %d %Y"), 'Chaos 1 3178', 'floating timezone');

done_testing();
