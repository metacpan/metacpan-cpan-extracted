#!perl -T
use 5.010;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 4;
use DarkSky::API;
use Data::Dumper;

my $darksky =
  DarkSky::API->new( api_key => '<your key here>' );

my $storms = $darksky->interesting();
ok( defined($storms), 'interesting' );

my $brief =
  $darksky->brief_forecast(
    { latitude => '40.7142', longitude => '-74.0064' } );
ok( defined($brief),'brief forecast' );

my $full =
  $darksky->forecast( { latitude => '40.7142', longitude => '-74.0064' } );
ok( defined($full), 'full forecast' );

my $precipitation = $darksky->precipitation(['42.7','-73.6',1325607100,'42.0','-73.0',1325607791]);
ok( defined($precipitation), 'precipitation' );
