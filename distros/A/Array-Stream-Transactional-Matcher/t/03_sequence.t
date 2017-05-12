# $Id: 03_sequence.t,v 1.10 2004/06/11 20:32:07 claes Exp $

use Test::More tests => 8;

BEGIN { use_ok('Array::Stream::Transactional::Matcher', qw(mkrule)); }
use Array::Stream::Transactional;
use strict;
no strict 'subs';

my $stream = Array::Stream::Transactional->new([1, 2, 3, 4, 5, 5, 2, 4, 1, 6, 5]);

# Test sequence
{
  $stream->reset;
  my $ok_2 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [[mkrule(Flow::sequence =>
									     mkrule(Value::eq => 2),
									     mkrule(Value::eq => 3),
									     mkrule(Value::eq => 4)),
								      sub { $ok_2++; }]]);
  $matcher->match($stream);
  ok($ok_2 == 1);
}

# Test repetition, 1 to INF
{
  $stream->reset;
  my $ok_3 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [[mkrule(Flow::sequence =>
									     mkrule(Value::eq => 4) =>
									     mkrule(Flow::repetition =>
										    mkrule(Value::eq => 5) =>
										    1),
									    ),
								      sub { $ok_3++; }]]);
  $matcher->match($stream);
  ok($ok_3 == 1);
}

# Test repetition, 2 => 3
{
  $stream->reset;
  my $ok_4 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [[mkrule(Flow::repetition =>
									     mkrule(Value::ge => 4) =>
									     2 => 3),
								      sub { $ok_4++; }]]);
  $matcher->match($stream);
  ok($ok_4 == 2);
}

# Test repetition, 1 => 1
{
  $stream->reset;
  my $ok_5 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [[mkrule(Flow::repetition =>
									     mkrule(Value::eq => 3) =>
									     1 => 1),
								      sub { $ok_5++; }]]);
  $matcher->match($stream);
  ok($ok_5 == 1);
}

# Test repetition, 2 => INF
{
  $stream->reset;
  my $ok_6 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [[ mkrule(Flow::repetition =>
									      mkrule(Value::ge => 5) =>
									      2),
								       sub { $ok_6++; }]]);
  $matcher->match($stream);
  ok($ok_6 == 2);
}

# Test 0 => INF
{
  $stream->reset;
  my $ok_7 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [[mkrule(Flow::sequence =>
									     mkrule(Logical::or =>
										    mkrule(Value::eq => 2),
										    mkrule(Value::eq => 3)),
									     mkrule(Flow::repetition =>
										    mkrule(Value::eq => 4),
										    0)),
								      sub { $ok_7++; }]]);
  $matcher->match($stream);
  ok($ok_7 == 3);
}

# Test optional
{
  $stream->reset;
  my $ok_8 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [[mkrule(Flow::sequence =>
									    mkrule(Value::eq => 2),
									    mkrule(Flow::optional =>
										   mkrule(Value::eq => 5)),
									    mkrule(Value::eq => 4)),
								     sub { $ok_8++; }]]);
  $matcher->match($stream);
  ok($ok_8 == 1);
}
