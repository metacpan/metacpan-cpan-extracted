
use strict;
use warnings FATAL => 'all';

use Apache::Test qw(:withtestmore);
use Test::More;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';

plan tests => 10;

ok 1; # simple load test

my $url = '/test/time';
my $data = GET_BODY $url;

my ($start_rt, $start_rt_us, $start_rd, $start_rd_us,
	$end_rt, $end_rt_us, $end_rd, $end_rd_us) = ($data =~ qr/
	^start:\n
	request_time \s \[(\d+)\]\n
	request_time_microseconds \s \[(\d+)\]\n
	request_duration \s \[(\d+)\]\n
	request_duration_microseconds \s \[(\d+)\]\n
	end:\n
	request_time \s \[(\d+)\]\n
	request_time_microseconds \s \[(\d+)\]\n
	request_duration \s \[(\d+)\]\n
	request_duration_microseconds \s \[(\d+)\]\n
	$/x);
ok(defined $end_rd_us, 'check output from /test/time');

SKIP: {
	if (defined $end_rd_us) {
		is($start_rt, substr($start_rt_us, 0, -6), 'strip last six digits to get seconds from us');

		is($start_rt, $end_rt, 'request_time stays the same');
		is($start_rt_us, $end_rt_us, '  even in microseconds');

		is($start_rd, 0, 'initial request_duration should be below 1');
		cmp_ok($start_rd_us, '<', 100000, '  and not more than 0.1 sec');

		cmp_ok($end_rd_us, '>', $start_rd_us + 2000000, 'after sleep of 2 sec, request_duration_microseconds should have bumped');
		cmp_ok($end_rd_us, '<', $start_rd_us + 2100000, '  but not too much');
		is($end_rd, 2, '  and it is 2 seconds');
	} else {
		diag "Response was:\n" . $data;
		skip 'failed to get proper output from test Apache', 8;
	}
}

