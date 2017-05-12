
use lib::abs '../lib';

package My::Client;

use base 'AnyEvent::Connection';

package main;

my $cl = My::Client->new(
	host      => '127.0.0.1',
	port      => 7,
	reconnect => 1,
	debug     => 0,
	timeout   => 1,
);
my $cv = AnyEvent->condvar;
my $fails = 0;
$cl->reg_cb(
	connected => sub {
		my ($cl,$con,$host,$port) = @_;
		warn "Connected $host:$port";
		$cl->disconnect('requested');
	},
	connfail => sub {
		my ($cl,$reason) = @_;
		warn "Connection failed: $reason";
		$fails++>1 and $cl->disconnect('failures');
	},
	disconnect => sub {
		my ($cl,$reason) = @_;
		warn "Disconnected: $reason";
		$cv->send;
	},
);
$cl->connect;
$cv->recv;

