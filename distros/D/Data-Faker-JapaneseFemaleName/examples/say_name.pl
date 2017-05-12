#!/usr/bin/env perl

use strict;
use warnings;

use Data::Faker qw/JapaneseFemaleName/;

my $faker = Data::Faker->new();

print "Name: ".$faker->japanese_female_name."\n";
