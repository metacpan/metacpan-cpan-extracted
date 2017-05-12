#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use DateTime;
use DateTime::Calendar::Discordian;

my @dates = (
    {day => 24, month => 7, year =>, -586, date => 'Confusion 59 580'},
    {day => 5, month => 12, year =>, -168, date => 'The Aftermath 47 998'},
    {day => 24, month => 9, year => 70, date => 'Bureaucracy 48 1236'},
    {day => 2, month => 10, year => 135, date => 'Bureaucracy 56 1301'},
    {day => 8, month => 1 , year => 470, date => 'Chaos 8 1636'},
    {day => 20, month => 5, year => 576, date => 'Discord 67 1742'},
    {day => 10, month => 11, year => 694, date => 'The Aftermath 22 1860'},
    {day => 25, month => 4, year => 1013, date => 'Discord 42 2179'},
    {day => 24, month => 5, year => 1096, date => 'Discord 71 2262'},
    {day => 23, month => 3, year => 1190, date => 'Discord 9 2356'},
    {day => 10, month => 3, year => 1240, date => 'Chaos 69 2406'},
    {day => 2, month => 4, year => 1288, date => 'Discord 19 2454'},
    {day => 27, month => 4, year => 1298, date => 'Discord 44 2464'},
    {day => 12, month => 6, year => 1391, date => 'Confusion 17 2557'},
    {day => 3, month => 2, year => 1436, date => 'Chaos 34 2602'},
    {day => 9, month => 4, year => 1492, date => 'Discord 26 2658'},
    {day => 19, month => 9, year => 1553, date => 'Bureaucracy 43 2719'},
    {day => 5, month => 3, year => 1560, date => 'Chaos 64 2726'},
    {day => 10, month => 6, year => 1648, date => 'Confusion 15 2814'},
    {day => 30, month => 6, year => 1680, date => 'Confusion 35 2846'},
    {day => 24, month => 7, year => 1716, date => 'Confusion 59 2882'},
    {day => 19, month => 6, year => 1768, date => 'Confusion 24 2934'},
    {day => 2, month => 8, year => 1819, date => 'Confusion 68 2985'},
    {day => 27, month => 3, year => 1839, date => 'Discord 13 3005'},
    {day => 19, month => 4, year => 1903, date => 'Discord 36 3069'},
    {day => 25, month => 8, year => 1929, date => 'Bureaucracy 18 3095'},
    {day => 29, month => 9, year => 1941, date => 'Bureaucracy 53 3107'},
    {day => 19, month => 4, year => 1943, date => 'Discord 36 3109'},
    {day => 7, month => 10, year => 1943, date => 'Bureaucracy 61 3109'},
    {day => 17, month => 3, year => 1992, date => 'Discord 3 3158'},
    {day => 25, month => 2, year => 1996, date => 'Chaos 56 3162'},
    {day => 10, month => 11, year => 2038, date => 'The Aftermath 22 3204'},
    {day => 18, month => 7, year => 2094, date => 'Confusion 53 3260'},
    {day => 31, month => 12, year => 2011, date => 'The Aftermath 73 3177'},
    {day => 31, month => 12, year => 2012, date => 'The Aftermath 73 3178'},
    {day => 1, month => 3, year => 2011, date => 'Chaos 60 3177'},
);

my $i = 1;
foreach my $d (@dates) {
    is(DateTime::Calendar::Discordian->from_object(
      object => DateTime->new(day => $d->{day}, month => $d->{month}, year => $d->{year}))
      ->strftime("%B %d %Y"), $d->{date}, "date $i");
    $i++;
}

done_testing();
