#!/usr/bin/env perl

use strict;
use warnings;
use FindBin::libs;

use POE;
use Bot::IKCBot::Pluggable;

our $irc_server = "irc.example.com";
our $irc_port   = 6667;
our @nick = qw(pluggabot pbot pluggable);

our $channel  = '#test1919';
our $ikc_ip   = '127.0.0.1',
our $ikc_port = 1919;
our $bot_name = 'ikchan',
eval { require "ikcbot-config.pl" };

# define my own state handler
$Bot::IKCBot::Pluggable::STATE_TABLE->{important} = "say_2times";
no warnings 'once';
*Bot::IKCBot::Pluggable::say_2times = sub {
    my($self, $arg) = @_[ OBJECT, ARG0 ];
    $self->say($arg);
    $self->say($arg);
};
use warnings 'once';


my $bot = Bot::IKCBot::Pluggable->new(
    channels => [$channel],
    server   => $irc_server,
    port     => $irc_port,

    nick     => $nick[0],
    altnicks => [ @nick[1..$#nick] ],
    username => "bot",
    name     => "Yet Another Pluggable Bot",

    ignore_list => [qw(shingo- shingo--)],

    verbose => 1,

    ALIASNAME => $bot_name,

    ikc_ip   => $ikc_ip,
    ikc_port => $ikc_port,
   );

$bot->load("Karma");
$bot->load("Join");

$bot->run;

__END__

# for Emacsen
# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8
# End:

# vi: set ts=4 sw=4 sts=0 :
