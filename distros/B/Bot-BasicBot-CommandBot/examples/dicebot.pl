#!/usr/bin/env perl

use strict;
use warnings;

$|=1;

my $bot = DiceBot->new(
    server => "irc.freenode.net",
    port   => "6667",
    channels => ["#some-chan"],

    nick      => "botreus",
    alt_nicks => ["lolbot", "cmdbot"],
    username  => "bot",
    name      => "Yet Another Bot",
    address   => 1,
);
$SIG{INT} = sub {$bot->shutdown};

package DiceBot;

use Bot::BasicBot::CommandBot qw(command);

use base 'Bot::BasicBot::CommandBot';
use List::Util qw/sum/;

command '1d6' => sub {
    return int(rand 6) + 1;
};

command qr/\d+d\d+/i => sub {
    my ($self, $cmd, $message) = @_;

    my ($num, $faces) = $cmd =~ /(\d+)d(\d+)/;

    my @rolls = map { int(rand $faces) + 1 } 1 .. $num;

    return join(", ", @rolls) . " = " . sum(0, @rolls);
};

package main;
$bot->run;
