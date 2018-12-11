#!/usr/bin/env perl

use CloudHealth::API;
use Data::Dumper;

my $ch = CloudHealth::API->new;

my $random_asset;
{
  my $res = $ch->ListOfQueryableAssets;
  print Dumper($res);
  $random_asset = $res->[0];
}

{
  my $res = $ch->AttributesOfSingleAsset(asset => $random_asset);
  print Dumper($res);
}
