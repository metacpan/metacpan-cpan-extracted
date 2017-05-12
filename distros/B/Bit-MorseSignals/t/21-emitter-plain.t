#!perl -T

use strict;
use warnings;

use Test::More 'no_plan';

use Bit::MorseSignals::Emitter;

my $deuce = Bit::MorseSignals::Emitter->new;

sub test_msg {
 my ($desc, $exp, $try_post) = @_;
 my $len = @$exp;
 my $last = pop @$exp;

 my $i = 0;
 for (@$exp) {
  is($deuce->pos, $deuce->busy ? $i : undef, "$desc: BME position is correct");
  my $b = $deuce->pop;
  if ($try_post) {
   ok(!defined($deuce->post),   "$desc: posting undef while sending returns undef");
   is($deuce->post('what'), -1, "$desc: posting while sending enqueues");
   $deuce->flush;
   is($deuce->queued, 0,        "$desc: flushing dequeues");
  }
  is($deuce->len, $len, "$desc: BME length is correct");
  ok($deuce->busy,      "$desc: BME object is busy after pop $i");
  is($b, $_,            "$desc: bit $i is correct");
  ++$i;
 }

 my $b = $deuce->pop;
 ok(!$deuce->busy, "$desc: BME object is no longer busy when over");
 is($b, $last,     "$desc: last bit is correct");
}

my $msg = 'x';
my @exp = split //, '111110' . '000' . '00011110' . '011111';

my $ret = eval { $deuce->post($msg, type => 4675412) }; # defaults to PLAIN
ok(!$@, "simple post doesn't croak ($@)");
ok(defined $ret && $ret > 0, 'simple post was successful');
ok($deuce->busy, 'BME object is busy after simple post');
ok(!$deuce->queued, 'BME object has no message queued after simple post');

test_msg 'simple post', [ @exp ], 1;
ok(!defined $deuce->pop, "simple post: message is over");

$ret = eval { $deuce->post($msg) };
ok(!$@, "first double post doesn't croak ($@)");
ok(defined $ret && $ret > 0, 'first double post was successful');
ok($deuce->busy, 'BME object is busy after first double post');
ok(!$deuce->queued, 'BME object has no message queued after first double post');

$ret = eval { $deuce->post($msg) };
ok(!$@, "second double post doesn't croak ($@)");
ok(defined $ret && $ret < 0, 'second double post was queued');
ok($deuce->busy, 'BME object is busy after second double post');
ok($deuce->queued, 'BME object has a message queued after second double post');

test_msg 'first double post', [ @exp ];
ok(!$deuce->busy && $deuce->queued, 'first double post: BME object is no longer busy but still has something in queue between the two posts');
test_msg 'second double post', [ @exp ];
ok(!defined $deuce->pop, "second double post: message is over");

my $exp1 = join '', @exp;
my $msg2 = 'y';
my $exp2 = '00001' . '000' . '10011110' . '10000';
my $msg3 = 'z';
my $exp3 = '000001' . '000' . '01011110' . '100000';

$deuce->post($msg);
$deuce->post($msg2);
my $s = ''; $s .= $deuce->pop for 1 .. length $exp1;
is($s, $exp1, 'first send successful');
ok(!$deuce->busy, 'after the first send, the emitter isn\'t busy anymore' );
is($deuce->queued, 1, 'after the fist send, the emitter has still one item queued');
isnt($deuce->post($msg3), -1, 'posting between the two messages doesn\'t return -1');
ok($deuce->busy, 'after the new post, the emitter is busy, ready to send');
is($deuce->queued, 1, 'after the new post, there\'s a new element in the queue');
$s = ''; $s .= $deuce->pop for 1 .. length $exp2;
is($s, $exp2, 'second send successful');
$s = ''; $s .= $deuce->pop for 1 .. length $exp3;
is($s, $exp3, 'third send successful');



