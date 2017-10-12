#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use MyApp;
use Plack::Builder;
use Plack::App::WebSocket;

builder {
    mount( MyApp->websocket_mount );
    mount '/' => MyApp->to_app;
}

