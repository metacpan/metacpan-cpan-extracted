use strict;
use Coro::Socket;
use Coro::PatchSet::Socket;

package SuperSocket;

our @ISA = 'Coro::Socket';

sub configure {
	my ($self, $args) = @_;
	
	if (exists $args->{SuperAddr}) {
		$args->{PeerAddr} = delete $args->{SuperAddr};
	}
	
	if (exists $args->{SuperPort}) {
		$args->{PeerPort} = delete $args->{SuperPort};
	}
	
	$self->SUPER::configure($args);
}

package main;

use Test::More;

my ($pid, $host, $port) = make_server();

my $sock = SuperSocket->new(SuperAddr => $host, SuperPort => $port);
is($sock->peerhost, $host, "PeerAddr ok");
is($sock->peerport, $port, "PeerPort ok");

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
