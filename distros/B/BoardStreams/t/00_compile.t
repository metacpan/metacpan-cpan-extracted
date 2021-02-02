use strict;
use Test::More 0.98;

use_ok $_ for qw(
    BoardStreams
    Mojolicious::Plugin::BoardStreams
    BoardStreams::Client::Channel
    BoardStreams::Client::Manager
    BoardStreams::Client::WebSocket
);

done_testing;
