use strict;
use warnings;
use Test::More tests => 10;

use AnyEvent;

BEGIN { use_ok('Data::Stream::Bulk::AnyEvent'); }

my $cv = AE::cv;
my @ret = ([1,2], [1,2], [3,4], [], [1,2], [3,4], [], undef);
my @expected = @ret;
my $stream =  Data::Stream::Bulk::AnyEvent->new(
	callback => sub {
		my $cv = AE::cv;
		my $ret = shift @ret;
		$cv->send($ret);
		return $cv;
	},
	cb => sub {
		my $got = shift->recv;
		my $expected = shift @expected;
		is_deeply($got, $expected);
		$cv->send unless defined $got;
		return defined $got;
	}
);

$cv->recv;
ok($stream->is_done, 'is_done');
