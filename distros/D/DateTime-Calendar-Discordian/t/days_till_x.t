#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use DateTime::Calendar::Discordian;

my @dates = (
    {season => 'Confusion', day => 1, year => 0, tillx => 3_589_277},
    {season => 'Confusion', day => 40, year => 9827, tillx => 0},
);

my $i = 1;
foreach my $d (@dates) {
    is(DateTime::Calendar::Discordian->new
      (season => $d->{season}, day => $d->{day}, year => $d->{year})->days_till_x, 
      $d->{tillx}, "date $i");
    $i++;
}

done_testing();
