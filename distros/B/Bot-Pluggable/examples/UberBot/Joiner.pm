
package UberBot::Joiner;
use strict;
use POE;

my @channels = (
    '#elizabot',
);

sub irc_001 {
    my ($self, $bot) = @_[OBJECT, SENDER];
    $bot->join($_) for @channels;
    return 0;
}

1;
