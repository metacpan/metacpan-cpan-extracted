# $Id: 02_logical.t,v 1.6 2004/06/11 20:32:07 claes Exp $

use Test::More tests => 5;

BEGIN { use_ok('Array::Stream::Transactional::Matcher', qw(mkrule)); }
use Array::Stream::Transactional;
use strict;
no strict 'subs';

my $stream = Array::Stream::Transactional->new([1, 2, 3, 4, 5]);

# Test and
{
  $stream->reset;
  my $ok_2 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [[mkrule(Logical::and => 
									     mkrule(Value::gt => 2),
									     mkrule(Value::lt => 4)),
								      sub { $ok_2++; }]]);

  $matcher->match($stream);
  ok($ok_2 == 1);
}

# Test or
{
  $stream->reset;
  my $ok_3 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [[mkrule(Logical::or =>
									     mkrule(Value::ge => 4),
									     mkrule(Value::eq => 1),
									     ),
								      sub { $ok_3++; }]]);
  $matcher->match($stream);
  ok($ok_3 == 3);
}

# Test xor
{
  $stream->reset;
  my $ok_4 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [[mkrule(Logical::xor => 
									     mkrule(Value::eq => 2),
									     mkrule(Value::eq => 5),
									     ),
								      sub { $ok_4++; }]]);
  $matcher->match($stream);
  ok($ok_4 == 2);
}

# Test not
{
  $stream->reset;
  my $ok_5 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [[mkrule(Logical::not =>
									     mkrule(Value::eq => 3),
									     ),
								      sub { $ok_5++; }]]);
  $matcher->match($stream);
  ok($ok_5 == 4);
}
