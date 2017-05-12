use strict; 
use Test::More;
use Coro::PatchSet::Socket;
use Coro::Socket;
use IO::Socket;

my $serv = IO::Socket::INET->new(Listen => 1);
my ($host, $port) = ($serv->sockhost eq "0.0.0.0" ? "127.0.0.1" : $serv->sockhost, $serv->sockport);
$serv->close();

my $sock = Coro::Socket->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);
is($sock, undef, "can't connect to destroyed server");

done_testing;
