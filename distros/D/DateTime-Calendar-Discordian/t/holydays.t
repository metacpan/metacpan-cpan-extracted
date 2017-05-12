#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use DateTime::Calendar::Discordian;

my @dates = (
    {season => 'Chaos', day => 1, year => 3178, name => q{}},
    {season => 'Chaos', day => 5, year => 3178, name => 'Mungday'},
    {season => 'Discord', day => 50, year => 3178, name => 'Discoflux'},
);

my $i = 1;
foreach my $d (@dates) {
    is(DateTime::Calendar::Discordian->new
      (season => $d->{season}, day => $d->{day}, year => $d->{year})->holyday, 
      $d->{name}, "date $i");
    $i++;
}

done_testing();
