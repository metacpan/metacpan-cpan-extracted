#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 6;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

{
  $v->put_string('000101011');
  $v->put_string('111010100');
  is($v->len, 18);
  $v->rewind_for_read;
  my $v1 = $v->read_string(6);
  is($v1, '000101');
  my $v2 = $v->read_string(6);
  is($v2, '011111');
  my $v3 = $v->read_string(6);
  is($v3, '010100');
  $v->rewind;
  my $v4 = $v->read_string(18);
  is($v4, '000101011111010100');
  $v->rewind;
  my $v5 = $v->read(18);
  is($v5,22484);
}
