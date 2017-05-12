#!/usr/bin/perl

use strict;
use warnings;
use Data::IPV4::Range::Parse qw(ALL_BITS);
use lib qw(../lib);


# so from here we can just parse some ranges

# parse and check a valid range
my $range_a=Data::Range::Compare::Stream::IPV4->parse_range('0/0');
if($range_a) {
  print "yes [$range_a] is valid\n";
}

# parse and check an invalid cidr 
my $range_b=Data::Range::Compare::Stream::IPV4->parse_range('0/');
unless($range_b) {
  print "no range_b is not valid!\n";
}

# build a new valid instance from integers
my $range_c=new Data::Range::Compare::Stream::IPV4(0,11);
if($range_c) {
  print "yes [$range_c] is valid\n";
}

# build an new range with the start value as invalid
my $range_d=new Data::Range::Compare::Stream::IPV4(-1,11);
unless($range_d) {
  print "No range_d is no valid\n";
}


# build an new range with the end value as invalid
my $range_e=new Data::Range::Compare::Stream::IPV4(0,(ALL_BITS + 1));
unless($range_e) {
  print "No range_e is no valid\n";
}

package Data::Range::Compare::Stream::IPV4;

use strict;
use warnings;
use Data::IPV4::Range::Parse qw(auto_parse_ipv4_range int_to_ip ALL_BITS);
use base qw(Data::Range::Compare::Stream);

use constant NEW_FROM_CLASS=>'Data::Range::Compare::Stream::IPV4';


# our sanity checking consists of 2 parts
# 1. overloading the bool operator
# 2. creating our boolean function

# Sanity check 1
# overloading the default bool operator and defining our boolean function
use overload
  bool=>\&boolean,
  fallback=>1
;

# Sanity check 2
sub boolean {
  my ($self)=@_;
  return undef unless defined($self->range_start);
  return undef unless defined($self->range_end);

  return 0 if $self->cmp_values($self->range_start,$self->range_end)==1;
  return 0 if $self->cmp_values($self->range_end,ALL_BITS)==1;
  return 0 if $self->cmp_values(0,$self->range_start)==1;

  1;
}

sub parse_range {
  my ($class,@args)=@_;
  my ($start,$end)= auto_parse_ipv4_range(@args);
  return $class->NEW_FROM_CLASS->new($start,$end);
}

sub range_start_to_string () {
  my ($self)=@_;
  return int_to_ip($self->range_start);
}

sub range_end_to_string () {
  my ($self)=@_;
  return int_to_ip($self->range_end);
}

1;
