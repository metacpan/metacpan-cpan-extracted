#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 2;

BEGIN { use_ok('Bot::BasicBot') };
my @methods = qw(
    new
    run

    init
    said
    emoted
    chanjoin
    chanpart
    got_names
    topic
    nick_change
    kicked
    tick
    help
    connected
    userquit

    schedule_tick
    forkit
    say
    notice
    emote
    reply
    channel_data

    server
    port
    password
    ssl
    nick
    alt_nicks
    username
    name
    channels
    quit_message
    ignore_list
    charset
    flood

    AUTOLOAD
    log
    ignore_nick
    nick_strip
    charset_decode
    charset_encode
);
can_ok('Bot::BasicBot', @methods);
