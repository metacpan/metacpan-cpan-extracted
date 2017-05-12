#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use_ok('Apache2::ASP::ConfigLoader');

for( 1...1 )
{
  my $config = Apache2::ASP::ConfigLoader->load;

  is(
    $config->errors->error_handler => 'My::ErrorHandler'
  );
  
  is(
    $config->system->settings->mysetting => 'value'
  );
  is(
    $config->system->settings->mysetting2 => 'value2'
  );
  
  foreach my $setting ( $config->system->settings )
  {
    like $setting->{name}, qr/^mysetting2?$/;
    like $setting->{value}, qr/^value2?$/;
  }# end foreach()
  
  is(
    $ENV{myvar} => 'value'
  );
  is(
    $ENV{myvar2} => 'value2'
  );
}

