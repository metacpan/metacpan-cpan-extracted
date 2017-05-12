#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use lib qw(t/lib);
use BitStreamTest;

my @implementations = impl_list;

#plan tests => scalar @implementations;

foreach my $type (@implementations) {

  my $encoding = 'unary';


  my $stream = new_stream($type);
  die unless defined $stream;
  my ($esub, $dsub, $param) = sub_for_string($encoding);
  die unless defined $esub and defined $dsub;

  $esub->($stream, $param, 1);
  $esub->($stream, $param, 2,3);
  $esub->($stream, $param, 4 .. 20);

  my $v;
  my @v;
  $stream->rewind_for_read;

  $v = $dsub->($stream, $param);
  ok($v == 1, "$type read scalar 1");
  @v = $dsub->($stream, $param);
  ok( (scalar @v == 1) && ($v[0] == 2), "$type read array 1");

  $v = $dsub->($stream, $param, 4);
  ok($v == 6, "$type read scalar 4");
  @v = $dsub->($stream, $param, 4);
  ok( (scalar @v == 4) && ($v[0] == 7) && ($v[3] == 10), "$type read array 4");

  $v = $dsub->($stream, $param, -1);
  ok( ($v == 20) && ($stream->pos == $stream->len), "$type read scalar -1");
  $stream->rewind_for_read;
  @v = $dsub->($stream, $param, -1);
  ok( (scalar @v == 20) && ($v[0] == 1) && ($v[19] == 20) && ($stream->pos == $stream->len), "$type read array -1");

  $stream->rewind_for_read;
  $v = $dsub->($stream, $param);
  my $lastpos = $stream->pos;
  $v = $dsub->($stream, $param, 0);
  ok( (!defined $v) && ($stream->pos == $lastpos), "$type read scalar 0");
  @v = $dsub->($stream, $param, 0);
  ok( (scalar @v == 0) && ($stream->pos == $lastpos), "$type read array 0");
}
done_testing();
