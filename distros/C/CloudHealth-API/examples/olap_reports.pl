#!/usr/bin/env perl

use CloudHealth::API;
use Data::Dumper;

my $ch = CloudHealth::API->new;

{
  my $res = $ch->ListQueryableReports;
  print Dumper($res);
}
{
  my $res = $ch->ListReportsOfSpecificType(type => 'cost');
  print Dumper($res);
}
{
  my $res = $ch->ListReportsOfSpecificType(type => 'custom');
  print Dumper($res);
}
