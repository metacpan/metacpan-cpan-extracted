#!/usr/bin/env perl

use CloudHealth::API;
use Data::Dumper;

my $ch = CloudHealth::API->new;

my $random_id;
{
  my $res = $ch->RetrieveAllPerspectives(active_only => 1);
  print Dumper($res);
  $random_id = [ keys %$res ]->[0];
}
{
  my $res = $ch->RetrievePerspectiveSchema(perspective_id => $random_id);
  print Dumper($res);
}
