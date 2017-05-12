use strict;
use Test::More;
use Coro::PatchSet;
use Coro::Socket;
use IO::Select;
use Time::HiRes;

my ($pid, $host, $port) = make_server();

my $sock = Coro::Socket->new(PeerAddr => $host, PeerPort => $port);
my $sele = IO::Select->new($sock);

for (1..10) {
	my $start = Time::HiRes::time();
	$sele->can_read();
	my $delay = Time::HiRes::time() - $start;
	ok($delay > 0.1 && $delay < 0.3, 'time spent for select looks good')
		or diag $delay, " sec spent";
	$sock->sysread(my $buf, 1024);
	is($buf, 'ABCDEFGHIJKLMNOPQRT', 'buf as expected');
}

if (ref $pid) {
	$pid->kill(15);
}
else {
	kill 15, $pid;
}

done_testing;

sub make_server {
	use IO::Socket;
	
	my $serv = IO::Socket::INET->new(Listen => 1);
	
	my $serv_code = sub {
		while (my $sock = $serv->accept()) {
			for (1..10) {
				select undef, undef, undef, 0.2;
				$sock->syswrite('ABCDEFGHIJKLMNOPQRT');
			}
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
