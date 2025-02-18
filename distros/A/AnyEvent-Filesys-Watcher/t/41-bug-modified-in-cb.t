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
	my @received;
	my $n = AnyEvent::Filesys::Watcher->new(
		directories => [$TestSupport::dir],
		callback => sub {
			push @received, @_;

			# This call back deletes any created files
			foreach my $event (@_) {
				unlink $event->path if $event->type eq 'created'
					&& !$event->isDirectory;
				if ('deleted' eq $event->type) {
					$done->send;
				}
			}
		},
		%extra_config,
	);
	isa_ok $n, 'AnyEvent::Filesys::Watcher';

	# Create a file, which will be delete in the callback
	create_test_files 'foo';

	my $timer = AnyEvent->timer(
		after => 5,
		cb => sub {
			ok 0, "lame test";
			$done->send;
		}
	);

	$done->recv;

	my $created_seen;
	my $deleted_seen;
	foreach my $event (@received) {
		if ($event->path =~ m{/foo$}) {
			if ('deleted' eq $event->type) {
				$deleted_seen = 1;
			} elsif ('created' eq $event->type) {
				$created_seen = 1;
			}
		}
	}
	ok $created_seen, 'created';
	ok $deleted_seen, 'deleted';
}

run_test;

SKIP: {
	skip 'Requires Mac with IO::KQueue', 3
		unless $^O eq 'darwin' and eval { require IO::KQueue; 1; };
	run_test backend => 'KQueue';
}

done_testing;
