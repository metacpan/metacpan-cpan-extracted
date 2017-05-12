#!/usr/bin/perl

use strict;
use warnings;
use lib qw(../lib);
use Data::Range::Compare::Stream;
use Data::Range::Compare::Stream::Iterator::Array;
use Data::Range::Compare::Stream::Iterator::Validate;


my $list=[
  Data::Range::Compare::Stream->new(),
  Data::Range::Compare::Stream->new(0),
  Data::Range::Compare::Stream->new(undef,0),
  Data::Range::Compare::Stream->new(1,0),
  Data::Range::Compare::Stream->new(0,0),
  Data::Range::Compare::Stream->new(1,2),
];

sub bad_range {
  my ($range)=@_;
  print "Invalid range found\n";
}

my $it=new Data::Range::Compare::Stream::Iterator::Array(range_list=>$list,sorted=>1);

my $valid=new Data::Range::Compare::Stream::Iterator::Validate($it,on_bad_range=>\&bad_range);
while($valid->has_next) {
  my $result=$valid->get_next;
  print $result,"\n";
}
