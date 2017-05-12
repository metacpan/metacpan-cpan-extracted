use strict;
use Test::More;
use Coro::PatchSet::Handle;
use Coro::Handle;
use Coro::Socket;

my ($pid, $host, $port) = make_slow_server();

my $sock = Coro::Socket->new(PeerAddr => $host, PeerPort => $port) or die $@;
my $readed = $sock->sysread(my $buf, 15);

is($readed, 9, "readed several bytes from slow server, less than requested");

if (ref $pid) {
	$pid->kill(15);
}
else {
	kill 15, $pid;
}

done_testing;

sub make_slow_server {
	use IO::Socket;
	
	my $serv = IO::Socket::INET->new(Listen => 1);
	
	my $serv_code = sub {
		while (my $sock = $serv->accept()) {
			$sock->syswrite("some data");
			sleep 5;
			$sock->syswrite("some more data");
			$sock->close();
		}
	};
	
	my $child;
	if ($^O eq 'MSWin32') {
		require threads;
		$child = threads->create(sub {
			$SIG{TERM} = sub { threads->exit() };
			$serv_code->();
		});
		$child->detach();
	}
	else {
		defined($child = fork())
			or die $!;
		
		if ($child == 0) {
			$serv_code->();
			exit;
		}
	}
	
	return ($child, $serv->sockhost eq "0.0.0.0" ? "127.0.0.1" : $serv->sockhost, $serv->sockport);
}
