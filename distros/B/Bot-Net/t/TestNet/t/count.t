use strict;
use warnings;

use lib 't/lib';
use Bot::Net::SubTest;
use Bot::Net::Test tests => 20;

# Make this test script a bot
use Bot::Net::Bot;
use Bot::Net::Mixin::Bot::IRC;

# Start the server in class MyBotNet::Server::Main
Bot::Net::Test->start_server('Main');

# Connect the bot in class MyBotNet::Bot::Count
Bot::Net::Test->start_bot('Count');

on bot connected => run {
    for ( 1 .. 10 ) {
        yield send_to => count => 'something';
    }
};

on bot message_to_me => run {
    my $event = get ARG0;
    my $count_expected = (recall('count') || 0) + 1;
    remember count => $count_expected;

    is($event->sender_nick, 'count');
    is($event->message, $count_expected);

    if ($count_expected == 10) {
        yield bot quit => 'Test finished.';
    }
};

# Startup this bot
Bot::Net::Test->run_test;
