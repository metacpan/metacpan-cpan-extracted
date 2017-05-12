#! /usr/bin/perl

use strict;
use warnings;

use Bot::BasicBot::Pluggable;

my $bot = Bot::BasicBot::Pluggable->new(
    server   => "irc.perl.org",
    port     => "6667",
    channels => ["#vdm"],
    
    nick     => "basicbot",
    name     => "Perl rulez",
    charset  => "utf-8",
    );

my $watch = $bot->load("VieDeMerde");

$bot->run();

