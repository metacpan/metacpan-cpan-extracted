#! /usr/bin/perl -w
use strict;

use Test::NoWarnings;
use Test::More tests => 30;

use Time::HiRes qw/sleep time/;

BEGIN { use_ok('Algorithm::TokenBucket'); }

my $bucket = Algorithm::TokenBucket->new(25/1, 4);
isa_ok($bucket, 'Algorithm::TokenBucket');
is($bucket->{info_rate}, 25, 'info_rate init');
is($bucket->{burst_size}, 4, 'burst_size init');
cmp_ok(abs($bucket->{_last_check_time} - time), '<', 0.1, 'check_time init');
cmp_ok($bucket->{_tokens}, '<', 0.01, 'tokens init');
cmp_ok($bucket->get_token_count, '<', 0.99, '~0 tokens in new bucket');
# get_token_count makes a tick so these two tests use different
# epsilons

sleep 0.3;
ok($bucket->conform(0), '0 conforms');
ok($bucket->conform(4), '4 conforms');
ok(!$bucket->conform(5), '5 does not conform');
$bucket->count(1);
ok(!$bucket->conform(4), '4 no more conforms');
ok($bucket->conform(3), 'only 3 does'); # point A
cmp_ok($bucket->get_token_count - 3, '<', 0.1, '~3 tokens indeed');
$bucket->count(1);
$bucket->count(1);
$bucket->count(1);
cmp_ok($bucket->get_token_count, '<', 0.9, '~0 tokens again');
ok(!$bucket->conform(1.1), '1.1 conforms no more'); # point B

# if had (4 - $SMALLNUM) tokens in point A and it took us long to
# reach point B due to CPU load then we could possibly end up
# with >1 tokens in point B.
# 
# In this case the bucket will conform to 1 or even more.
# I greatly reduce the probability of test failure by testing
# conformity to 1 + 0.1 (which is a kind of huge $SMALLNUM).

$bucket->count(1000);
is($bucket->{_tokens}, 0, '-= 1000 drained bucket to 0');

# pass 50 within 2 seconds
my $traffic = 50;
my $time = time;
while (time - $time < 2) {
    if ($bucket->conform(1)) {
        $bucket->count(1);
        $traffic--;
    }
}
cmp_ok($traffic, '>=', 0, '50 or less in 2 seconds');

$bucket = Algorithm::TokenBucket->new(25/1, 4); # start afresh (point C)

my @state = $bucket->state;
is($state[0], 25, 'state[0]');
is($state[1], 4, 'state[1]');
cmp_ok($state[2], '<', 0.01, 'state[2]');
cmp_ok(abs($state[3] - time), '<', 0.1, 'state[3]');

my $bucket1 = Algorithm::TokenBucket->new(@state);
isa_ok($bucket1, 'Algorithm::TokenBucket');
ok(!$bucket1->conform(2), 'restored bucket is almost empty'); # point D
# if it took us long (>1/25 sec) from point C up to point D, conform(1) could be true
sleep 0.1;
ok($bucket1->conform(2), 'restored bucket works');

is($bucket1->until(1), 0, 'no wait time for 1');
cmp_ok(my $t = $bucket1->until(500), '>=', 5, 'wait time');
cmp_ok(my $t2 = $bucket1->until(1000), '>=', $t, 'bigger wait time for a bigger number');
cmp_ok( ( ( $t2 - $t ) - ( 500 / 25 ) ), '<=', 1, 'until() is sort of accurate');

SKIP: {
	skip "no Storable", 1 unless eval { require Storable };

	my $bucket1_clone = Storable::thaw(Storable::freeze($bucket1));

	is_deeply(
		# allows for some error margin due to serialization
		[ map { (int($_ * 100)/100) } $bucket1->state ],
		[ map { (int($_ * 100)/100) } $bucket1_clone->state ],
		"state is the same"
	);
}
