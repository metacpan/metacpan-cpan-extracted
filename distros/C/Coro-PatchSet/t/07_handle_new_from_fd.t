use strict;
use Test::More;
use Coro::Socket;
use Coro::PatchSet::Handle;
use IO::Handle;
use IO::Socket;

my $serv = IO::Socket::INET->new(Listen => 1)
	or die $@;

my $clnt = Coro::Socket->new(
	PeerAddr => $serv->sockhost eq '0.0.0.0' ? '127.0.0.1' : $serv->sockhost,
	PeerPort => $serv->sockport,
	Timeout  => 5
) or die $@;

my $dup = IO::Handle->new_from_fd($clnt, '+<');
ok($dup, 'new_from_fd on Coro::Socket')
	or diag "Error: $!";

done_testing;
