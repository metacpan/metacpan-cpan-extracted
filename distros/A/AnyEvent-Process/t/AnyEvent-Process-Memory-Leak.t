# A test case to reproduce issue 101915
# The test case was written by Bob Kleemann
use strict;

use Test::More tests => 1;
use AnyEvent;
use AnyEvent::Process;
use Errno qw(:POSIX);

SKIP: {
	eval { require Devel::SizeMe };
	skip "Devel::SizeMe is required", 1 if $@;

	my $initial_size;
	for (1..10_000) {
		my $arg = rand;
		my ( $stdout, $stderr ) = ( '', '' );
		my $cv  = AnyEvent->condvar;
		my $job = AnyEvent::Process->new(
			args          => [ $arg ],
			code          => sub { exec 'echo', @_ },
			kill_interval => 10,
			on_completion => sub {
			my ( $job, $exit ) = @_;
				$cv->send($exit);
			},
			on_kill  => sub {
				my $job = shift;
				$job->kill(9);
				$cv->send(-1);
			},
			fh_table => [
				\*STDOUT => [
					qw( pipe > handle ),
					[
						on_eof   => sub { },    # Ignore EOF
						on_read  => sub { $stdout = $_[0]->rbuf },
						on_error => sub { return if $! == EPIPE },
					]
				],
				\*STDERR => [
					qw( pipe > handle ),
					[
						on_eof   => sub { },    # Ignore EOF
						on_read  => sub { $stderr = $_[0]->rbuf },
						on_error => sub { return if $! == EPIPE },
					]
				],
			]
		);
		my $run = $job->run();
		my $return = $cv->recv;
		die $return if $return;

		$initial_size = Devel::SizeMe::perl_size() if $_ == 25;
	}

	my $final_size = Devel::SizeMe::perl_size();

	diag "INITIAL: $initial_size  FINAL: $final_size";
	cmp_ok(1000*$final_size/$initial_size, '<=', 1001, "Memory doesn't leak");
};
