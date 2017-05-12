#!/usr/bin/perl

use strict;
use warnings;

use POE qw(Component::IRC);
use Bot::R9K;


my $irc = POE::Component::IRC->spawn(
    nick        => 'Bot-R9K',
    server      => 'irc.botnet.org',
    port        => 6667,
    ircname     => 'R9K',
    username    => 'r9k',
    debug       => 1,
);

POE::Session->create(
    package_states => [
        main => [ qw(_start irc_001) ],
    ],
);

$poe_kernel->run;

sub _start {
    $irc->yield( register => 'all' );
    
    $irc->plugin_add(
        'R9K' =>
            Bot::R9K->new
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $_[kernel]->post( $_[sender] => join => '#channel' );
}
