#!/usr/bin/perl -w

use strict;
use warnings 'all';
use lib qw( t/lib );
use Test::More 'no_plan';

use_ok('My::State');
use_ok('My::City');
use_ok('My::Zipcode');

my $state = My::State->find_or_create(
  state_name  => 'California',
  state_abbr  => 'CA'
);
my $burbank = My::City->find_or_create(
  state_id    => $state->id,
  city_name   => 'Burbank'
);
my $glendale = My::City->find_or_create(
  state_id    => $state->id,
  city_name   => 'Glendale'
);
my $zip = My::Zipcode->find_or_create(
  city_id   => $burbank->id,
  zipcode   => 91501,
);

is_deeply(
  $zip->city  => $burbank,
  "91501 belongs to Burbank"
);

is_deeply(
  $burbank->zipcode => $zip,
  "Burbank's Zipcode is 91501"
);

$zip->city_id( $glendale->id );
$zip->update;

is_deeply(
  $zip->city  => $glendale,
  "91501 now belongs to Glendale"
);

is_deeply(
  $glendale->zipcode  => $zip,
  "Glendale's Zipcode is now 91510"
);

$zip->city_id( $burbank->id );
$zip->update;


# Now test the new search args allowed in the has_many methods:
CITIES: {
  my ($burbank2) = $state->cities({ city_name => 'Burbank'});
  is_deeply $burbank2, $burbank, "Got Burbank alright";
  
  my ($glendale2) = $state->cities({ city_name => 'Glendale'});
  is_deeply $glendale2, $glendale, "Got Glendale alright";
  
  my ($burbank3) = $state->cities({ city_name => {'!=' => 'Glendale'}});
  is_deeply $burbank3, $burbank, "Got Burbank again";
  
  my ($glendale3) = $state->cities(undef, { order_by => 'city_id DESC LIMIT 0, 1'} );
  is_deeply $glendale3, $glendale, "Got Glendale by id reversed";
};



