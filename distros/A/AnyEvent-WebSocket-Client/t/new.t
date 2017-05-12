use strict;
use warnings;
use Test::More tests => 1;
use AnyEvent::WebSocket::Client;

my $client = AnyEvent::WebSocket::Client->new;
isa_ok $client, 'AnyEvent::WebSocket::Client';
