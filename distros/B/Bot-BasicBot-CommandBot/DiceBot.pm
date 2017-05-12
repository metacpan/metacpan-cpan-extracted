package DiceBot;
use strict;
use warnings;

use Bot::BasicBot::CommandBot qw/command/;
use List::Util qw/sum/;

use base 'Bot::BasicBot::CommandBot';

command '1d6' => sub {
    return int(rand 6) + 1;
};

command qr/\d+d\d+/i => sub {
    my ($self, $cmd, $message) = @_;

    my ($num, $faces) = $cmd =~ /(\d+)d(\d+)/;

    my @rolls = map { int(rand $faces) + 1 } 1 .. $num;

    return join(", ", @rolls) . " = " . sum(0, @rolls);
};

1;
