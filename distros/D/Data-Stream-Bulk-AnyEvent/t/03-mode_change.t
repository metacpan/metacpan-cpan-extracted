use strict;
use warnings;
use Test::More tests => 19;

use AnyEvent;

BEGIN { use_ok('Data::Stream::Bulk::AnyEvent'); }

my @ret = (([1,2], [3,4], [], [5,6], [1,2]) x 3, undef);
my @expected = @ret;
my $stream =  Data::Stream::Bulk::AnyEvent->new(
	callback => sub {
		my $cv = AE::cv;
		my $ret = shift @ret;
		$cv->send($ret);
		return $cv;
	},
);

# Blocking mode

ok(! $stream->is_done, '!is_done in initial');
is_deeply($stream->next, shift @expected);
is_deeply($stream->next, shift @expected);
is_deeply($stream->next, shift @expected);

# Blocking to callback

my $cv = AE::cv;
my $count = 3;
$stream->cb(sub {
	my $got = shift->recv;
	is_deeply($got, shift @expected);
	$cv->send unless --$count;
	return $count;
});

# Callback to blocking by next

$cv->recv;
is_deeply($stream->next, shift @expected);
is_deeply($stream->next, shift @expected);
is_deeply($stream->next, shift @expected);

# Blocking to callback

$cv = AE::cv;
$count = 3;
$stream->cb(sub {
	my $got = shift->recv;
	is_deeply($got, shift @expected);
	$cv->send unless --$count;
	return $count;
});

# Callback to blocking by setting callback as undef

$cv->recv;
$stream->cb(undef);
foreach my $expected (@expected) {
	is_deeply($stream->next, $expected);
}

ok($stream->is_done, 'is_done');
