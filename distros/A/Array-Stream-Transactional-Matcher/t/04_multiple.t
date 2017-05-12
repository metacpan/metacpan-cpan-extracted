# $Id: 04_multiple.t,v 1.3 2004/06/11 20:32:07 claes Exp $

use Test::More tests => 5;

BEGIN { use_ok('Array::Stream::Transactional::Matcher', qw(mkrule)); }
use Array::Stream::Transactional;
use strict;
no strict 'subs';

my $stream = Array::Stream::Transactional->new([1, 2, 3, 4, 5, 5, 2, 4, 1, 6, 5]);

my $two_or_three = mkrule(Logical::or =>
			  mkrule(Value::eq => 2),
			  mkrule(Value::eq => 3));

my $six_follows_one = mkrule(Flow::sequence =>
			     mkrule(Value::eq => 1),
			     mkrule(Value::eq => 6));

my $multiple_five_follows_four = mkrule(Flow::sequence =>
					mkrule(Value::eq => 4),
					mkrule(Flow::repetition =>
					       mkrule(Value::eq => 5),
					       1));

{
  $stream->reset;
  my $ok_2 = 0;
  my $ok_3 = 0;
  my $ok_4 = 0;
  my $ok_5 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [ $two_or_three,
								      $six_follows_one,
								      $multiple_five_follows_four ],
							   call => sub {
							     my $rule = shift;
							     if($rule eq $two_or_three) {
							       $ok_2++;
							     } elsif($rule eq $six_follows_one) {
							       $ok_3++;
							     } elsif($rule eq $multiple_five_follows_four) {
							       $ok_4++;
							     } else {
							       $ok_5++;
							     }
							   });

  $matcher->match($stream);
  ok($ok_2 == 3);
  ok($ok_3 == 1);
  ok($ok_4 == 1);
  ok($ok_5 == 0);
}
