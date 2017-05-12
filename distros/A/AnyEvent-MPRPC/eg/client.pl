use strict;
use warnings;
use AnyEvent;
use AnyEvent::MPRPC::Client;
use Smart::Comments;
use Test::More;

my $client = AnyEvent::MPRPC::Client->new(
    host => 'localhost',
    port => 1984,
);
my $ret = $client->call('sum' => [qw/1 2 3/])->recv;
is $ret, 6;

done_testing;
