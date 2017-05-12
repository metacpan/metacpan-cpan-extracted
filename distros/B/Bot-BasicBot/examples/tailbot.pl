#!/usr/bin/perl -w

=head1 NAME

tailbot

=head1 DESCRIPTION

from the fbi bot by richardc, tails a file called 'logfile' to the channel
#tailbot.

=cut

use warnings;
use strict;

package TailBot;
use base 'Bot::BasicBot';

my $channel = '#tailbot';

sub connected {
    my $self = shift;
    $self->forkit({ channel => $channel,
                    run     => [ qw( /usr/bin/tail -f logfile ) ],
                 });
}

package main;

TailBot->new(nick => 'tailbot', channels => [ $channel ])
       ->run;
