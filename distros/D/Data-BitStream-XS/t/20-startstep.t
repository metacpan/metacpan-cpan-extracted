#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 4;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

my @a = 0 .. 257;
my $nitems = scalar @a;

if(1){
  $v->erase_for_write;
  $v->put_startstop([3,8], @a);
  $v->rewind_for_read;
  my @vals = $v->get_startstop([3,8], -1);
  is_deeply( \@vals, \@a, "ss(3-8) 0-257");
}
{
  $v->erase_for_write;
  $v->put_startstop([0,3,8], @a);
  $v->rewind_for_read;
  my @vals = $v->get_startstop([0,3,8], -1);
  is_deeply( \@vals, \@a, "ss(0-3-8) 0-257");
}
if(1){
  $v->erase_for_write;
  $v->put_startstop([1,0,1,0,2,12,99], @a);
  $v->rewind_for_read;
  my @vals = $v->get_startstop([1,0,1,0,2,12,99], -1);
  is_deeply( \@vals, \@a, "ss(1-0-1-0-2-12-99) 0-257");
}
if(1){
  $v->erase_for_write;
  $v->put_startstepstop([3,3,99], @a);
  $v->rewind_for_read;
  my @vals = $v->get_startstepstop([3,3,99], -1);
  is_deeply( \@vals, \@a, "sss(3-3-99) 0-257");
}
