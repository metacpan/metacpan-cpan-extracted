#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use DateTime::Calendar::Discordian;

my @dates = (
    {season => 'Confusion', day => 59, year => 580, abbr => 'SO'},
    {season => 'The Aftermath', day => 47, year => 998, abbr => 'PP'},
    {season => 'Bureaucracy', day => 48, year => 1236, abbr => 'BT'},
    {season => 'Bureaucracy', day => 56, year => 1301, abbr => 'SO'},
    {season => 'Chaos', day => 8, year => 1636, abbr => 'PD'},
    {season => 'Discord', day => 67, year => 1742, abbr => 'SO'},
    {season => 'The Aftermath', day => 22, year => 1860, abbr => 'PP'},
    {season => 'Discord', day => 42, year => 2179, abbr => 'SO'},
    {season => 'Discord', day => 71, year => 2262, abbr => 'PP'},
    {season => 'Discord', day => 9, year => 2356, abbr => 'BT'},
    {season => 'Chaos', day => 69, year => 2406, abbr => 'PP'},
    {season => 'Discord', day => 19, year => 2454, abbr => 'BT'},
    {season => 'Discord', day => 44, year => 2464, abbr => 'BT'},
    {season => 'Confusion', day => 17, year => 2557, abbr => 'PD'},
    {season => 'Chaos', day => 34, year => 2602, abbr => 'PP'},
    {season => 'Discord', day => 26, year => 2658, abbr => 'PP'},
    {season => 'Bureaucracy', day => 43, year => 2719, abbr => 'BT'},
    {season => 'Chaos', day => 64, year => 2726, abbr => 'PP'},
    {season => 'Confusion', day => 15, year => 2814, abbr => 'SM'},
    {season => 'Confusion', day => 35, year => 2846, abbr => 'SM'},
    {season => 'Confusion', day => 59, year => 2882, abbr => 'SO'},
    {season => 'Confusion', day => 24, year => 2934, abbr => 'SO'},
    {season => 'Confusion', day => 68, year => 2985, abbr => 'PP'},
    {season => 'Discord', day => 13, year => 3005, abbr => 'SM'},
    {season => 'Discord', day => 36, year => 3069, abbr => 'PP'},
    {season => 'Bureaucracy', day => 18, year => 3095, abbr => 'BT'},
    {season => 'Bureaucracy', day => 53, year => 3107, abbr => 'BT'},
    {season => 'Discord', day => 36, year => 3109, abbr => 'PP'},
    {season => 'Bureaucracy', day => 61, year => 3109, abbr => 'SO'},
    {season => 'Discord', day => 3, year => 3158, abbr => 'SM'},
    {season => 'Chaos', day => 56, year => 3162, abbr => 'SM'},
    {season => 'The Aftermath', day => 22, year => 3204, abbr => 'PP'},
    {season => 'Confusion', day => 53, year => 3260, abbr => 'PP'},
    {day => q{St. Tib's Day}, year => 3178, abbr => undef },
);

my $i = 1;
foreach my $d (@dates) {
    is(DateTime::Calendar::Discordian->new
      (season => $d->{season}, day => $d->{day}, year => $d->{year})->day_abbr, 
      $d->{abbr}, "date $i");
    $i++;
}

done_testing();
