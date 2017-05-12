use strict;

use Test::More tests => 16;
use AnyEvent;

use_ok('AnyEvent::Process');

my $job;
my $cv = AE::cv;
my $watchdog_rtn = 2;
my $proc = new AnyEvent::Process(
	on_watchdog => sub {
		ok($watchdog_rtn >= 0, 'Callback on_watchdog called');
		ok($job == $_[0], 'First argument of on_watchdog is job reference.');
		return $watchdog_rtn--;
	},
	watchdog_interval => 2,
	on_kill => sub {
		ok($watchdog_rtn == -1, 'Callback on_kill called');
		ok($job == $_[0], 'First argument of on_kill is job reference.');
		$_[0]->kill(9);
	},
	on_completion => sub { 
		ok($job == $_[0], 'First argument of on_completion is a job reference.');
		ok(9 == $_[1], 'Second argument of on_completion is an exit code.');
		$cv->send('DONE') 
	},
	code => sub {
		sleep 10;
		return 0;
	});

$job = $proc->run();
is($cv->recv, 'DONE', 'Process exited.');

# Test killing after specified interval
$cv = AE::cv;
$proc = new AnyEvent::Process(
	on_completion => sub { 
		ok($job == $_[0], 'First argument of on_completion is a job reference.');
		ok(9 == $_[1], 'Second argument of on_completion is an exit code.');
		$cv->send('DONE') 
	},
	kill_interval => 2,
	code => sub {
		sleep 4,
		return 0,
	});

my $start = time;
$job = $proc->run(),
is($cv->recv, 'DONE', 'Process exited.');
my $finnish = time;

ok($finnish - $start <= 3 && $finnish - $start >= 2, 'Process was terminated on time')
