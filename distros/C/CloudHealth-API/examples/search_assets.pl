#!/usr/bin/env perl

use CloudHealth::API;
use Data::Dumper;

my $ch = CloudHealth::API->new;

{
  my $res = $ch->SearchForAssets(
    name => 'AwsInstance',
    query => 'is_active=1',
  );
  print Dumper($res);
}

