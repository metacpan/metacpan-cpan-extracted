#!/usr/bin/perl

use strict;
use warnings;
use lib qw(../lib);

use Data::Range::Compare::Stream::Iterator::Consolidate;
use Data::Range::Compare::Stream::Iterator::Array;
use Data::Range::Compare::Stream;
use Data::Range::Compare::Stream::Iterator::Consolidate::FillMissing;

my $array=Data::Range::Compare::Stream::Iterator::Array->new;

$array->create_range(0,0);
$array->create_range(1,1);
$array->create_range(3,4);
$array->create_range(6,7);
$array->set_sorted(1);

my $con=Data::Range::Compare::Stream::Iterator::Consolidate->new($array);

my $fill=new Data::Range::Compare::Stream::Iterator::Consolidate::FillMissing($con);

while($fill->has_next) {
  my $result=$fill->get_next;
  my $missing=$result->is_missing ? ' Gap' : '';
  print '  ',$result,$missing,"\n";
}

