#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use lib qw(../lib);

use Data::Range::Compare::Stream;
use Data::Range::Compare::Stream::Iterator::Array;
use Data::Range::Compare::Stream::Iterator::Consolidate::AdjacentAsc;


my $iterator=new Data::Range::Compare::Stream::Iterator::Array;

$iterator->create_range(0,0);
$iterator->create_range(1,2);
$iterator->create_range(4,6);
$iterator->create_range(7,9);

$iterator->prepare_for_consolidate_asc;
my $consolidator=Data::Range::Compare::Stream::Iterator::Consolidate::AdjacentAsc->new($iterator);

while($consolidator->has_next) {
  my $result=$consolidator->get_next;
  print $result,"\n";
}
