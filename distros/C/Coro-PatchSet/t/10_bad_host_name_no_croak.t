use strict;
use Test::More;
use Coro::Socket;
use Coro::PatchSet::Socket;

my $sock = eval { Coro::Socket->new(PeerAddr => '...', PeerPort => 80, Timeout => 5) };
ok(!$@, 'not died');

done_testing;
