use strict;
use warnings;

use Test::More;

use AnyEvent;
use AnyEvent::Filesys::Watcher;
use lib 't/lib';
use TestSupport qw(create_test_files delete_test_files);

if ($^O eq 'MSWin32' ) {
	plan skip_all => 'Test temporarily disabled for MSWin32';
}

$|++;

sub run_test {
	my %extra_config = @_;

	my $done = AnyEvent->condvar;
	my @raw;
	my @cooked;
	my $n = AnyEvent::Filesys::Watcher->new(
		directories => [$TestSupport::dir],
		callback => sub {},
		raw_events => sub {
			push @raw, @_;
			$done->send if @raw >= 3;
			return @_;
		},
		%extra_config,
	);
	isa_ok $n, 'AnyEvent::Filesys::Watcher';

	# Create a file, which will be delete in the callback
	create_test_files 'foo', 'bar', 'baz';

	my $timer = AnyEvent->timer(
		after => 5,
		cb => sub {
			ok 0, "lame test";
			$done->send;
		}
	);

	$done->recv;
	ok scalar @raw >= 3, 'at least 3 events received';
}

run_test;

SKIP: {
	skip 'Requires Mac with IO::KQueue', 3
		unless $^O eq 'darwin' and eval { require IO::KQueue; 1; };
	run_test backend => 'KQueue';
}

done_testing;
