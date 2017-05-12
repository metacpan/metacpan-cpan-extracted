use strict;
use warnings;
use Test::More tests => 11;

use AnyEvent;

BEGIN { use_ok('Data::Stream::Bulk::AnyEvent'); }

{
	my @ret = ([1,2], [1,2], [3,4], [1,2], [3,4], [], undef);
	my @expected = @ret; pop @expected;
	my $stream =  Data::Stream::Bulk::AnyEvent->new(
		callback => sub {
			my $cv = AE::cv;
			my $ret = shift @ret;
			$cv->send($ret);
			return $cv;
		},
	);
	is_deeply([$stream->all], [map { @$_ } @expected]);
	ok($stream->is_done, 'is_done');
}
{
	my @ret = ([1,2], [1,2], [3,4], [1,2], [3,4], [], undef);
	my @expected = @ret;
	my $stream =  Data::Stream::Bulk::AnyEvent->new(
		callback => sub {
			my $cv = AE::cv;
			my $ret = shift @ret;
			$cv->send($ret);
			return $cv;
		},
	);
	foreach my $value (@expected) {
		is_deeply([$stream->items], defined($value) ? $value : []);
	}
	ok($stream->is_done, 'is_done');
}
