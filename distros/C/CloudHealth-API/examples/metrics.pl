#!/usr/bin/env perl

use strict;
use warnings;


use CloudHealth::API;
use Data::Dumper;

my $asset = $ARGV[0] or die "Usage: $0 asset_id";

my $ch = CloudHealth::API->new;

{
  my $res = $ch->MetricsForSingleAsset(
    asset => $asset,
  );
  print Dumper($res);
}

