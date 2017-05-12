use strict;
use warnings;

package TestNet::Bot::Count;

use Bot::Net::Bot;
use Bot::Net::Mixin::Bot::IRC;

on bot start => run {
    remember counter => 0;
};

on bot message_to_me => run {
    my $event = get ARG0;

    my $counter = (recall('counter') || 0) + 1;
    remember counter => $counter;

    yield reply_to_sender => $event => $counter;
};

1;
