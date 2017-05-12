# $Id: 01_value.t,v 1.5 2004/06/11 20:32:07 claes Exp $

use Test::More tests => 8;

BEGIN { use_ok('Array::Stream::Transactional::Matcher', qw(mkrule)); }
use Array::Stream::Transactional;
use strict;
no strict 'subs';

my $obj = bless [], "Foo";

my $stream = Array::Stream::Transactional->new([1, 2, 3, $obj, 4, 5]);

# Test value equals
{
  $stream->reset;
  my $ok_2 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [ [mkrule(Value::eq => 1),
								       sub { $ok_2++; } ]]);
  $matcher->match($stream);
  ok($ok_2 == 1);
}

# Test value not equals
{
  $stream->reset;
  my $ok_3 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [ [mkrule(Value::ne => 2),
								       sub { $ok_3++; }]]);
  $matcher->match($stream);
  ok($ok_3 == 5);
}
   
# Test value is greater
{
  $stream->reset;
  my $ok_4 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [ [mkrule(Value::gt => 3),
								       sub { $ok_4++; }]]);
  $matcher->match($stream);
  ok($ok_4 == 3);
}

# Test value is less
{
  $stream->reset;
  my $ok_5 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [ [mkrule(Value::lt => 3),
								       sub { $ok_5++; }]]);
  $matcher->match($stream);
  ok($ok_5 == 2);
}

# Test value is greater or equal
{
  $stream->reset;
  my $ok_6 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [ [mkrule(Value::ge => 3),
								       sub { $ok_6++; }]]);
  $matcher->match($stream);
  ok($ok_6 == 4);
}

# Test value is less or equal
{
  $stream->reset;
  my $ok_7 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [ [mkrule(Value::le => 3),
								       sub { $ok_7++; }]]);
  $matcher->match($stream);
  ok($ok_7 == 3);
}

# Test value is-a
{
  $stream->reset;
  my $ok_8 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [ [mkrule(Value::isa => "Foo"),
								       sub { $ok_8++; }]]);
  $matcher->match($stream);
  ok($ok_8 == 1);
}
