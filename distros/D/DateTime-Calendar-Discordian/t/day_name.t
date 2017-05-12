#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use DateTime::Calendar::Discordian;

my @dates = (
    {season => 'Confusion', day => 59, year => 580, name => 'Setting Orange'},
    {season => 'The Aftermath', day => 47, year => 998, name => 'Prickle-Prickle'},
    {season => 'Bureaucracy', day => 48, year => 1236, name => 'Boomtime'},
    {season => 'Bureaucracy', day => 56, year => 1301, name => 'Setting Orange'},
    {season => 'Chaos', day => 8, year => 1636, name => 'Pungenday'},
    {season => 'Discord', day => 67, year => 1742, name => 'Setting Orange'},
    {season => 'The Aftermath', day => 22, year => 1860, name => 'Prickle-Prickle'},
    {season => 'Discord', day => 42, year => 2179, name => 'Setting Orange'},
    {season => 'Discord', day => 71, year => 2262, name => 'Prickle-Prickle'},
    {season => 'Discord', day => 9, year => 2356, name => 'Boomtime'},
    {season => 'Chaos', day => 69, year => 2406, name => 'Prickle-Prickle'},
    {season => 'Discord', day => 19, year => 2454, name => 'Boomtime'},
    {season => 'Discord', day => 44, year => 2464, name => 'Boomtime'},
    {season => 'Confusion', day => 17, year => 2557, name => 'Pungenday'},
    {season => 'Chaos', day => 34, year => 2602, name => 'Prickle-Prickle'},
    {season => 'Discord', day => 26, year => 2658, name => 'Prickle-Prickle'},
    {season => 'Bureaucracy', day => 43, year => 2719, name => 'Boomtime'},
    {season => 'Chaos', day => 64, year => 2726, name => 'Prickle-Prickle'},
    {season => 'Confusion', day => 15, year => 2814, name => 'Sweetmorn'},
    {season => 'Confusion', day => 35, year => 2846, name => 'Sweetmorn'},
    {season => 'Confusion', day => 59, year => 2882, name => 'Setting Orange'},
    {season => 'Confusion', day => 24, year => 2934, name => 'Setting Orange'},
    {season => 'Confusion', day => 68, year => 2985, name => 'Prickle-Prickle'},
    {season => 'Discord', day => 13, year => 3005, name => 'Sweetmorn'},
    {season => 'Discord', day => 36, year => 3069, name => 'Prickle-Prickle'},
    {season => 'Bureaucracy', day => 18, year => 3095, name => 'Boomtime'},
    {season => 'Bureaucracy', day => 53, year => 3107, name => 'Boomtime'},
    {season => 'Discord', day => 36, year => 3109, name => 'Prickle-Prickle'},
    {season => 'Bureaucracy', day => 61, year => 3109, name => 'Setting Orange'},
    {season => 'Discord', day => 3, year => 3158, name => 'Sweetmorn'},
    {season => 'Chaos', day => 56, year => 3162, name => 'Sweetmorn'},
    {season => 'The Aftermath', day => 22, year => 3204, name => 'Prickle-Prickle'},
    {season => 'Confusion', day => 53, year => 3260, name => 'Prickle-Prickle'},
    {day => q{St. Tib's Day}, year => 3178, name => q{St. Tib's Day} },
);

my $i = 1;
foreach my $d (@dates) {
    is(DateTime::Calendar::Discordian->new
      (season => $d->{season}, day => $d->{day}, year => $d->{year})->day_name, 
      $d->{name}, "date $i");
    $i++;
}

done_testing();
