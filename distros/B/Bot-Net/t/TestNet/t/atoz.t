use strict;
use warnings;

use lib 't/lib';
use Bot::Net::SubTest;
use Bot::Net::Test tests => 52;

# Make this test script a bot
use Bot::Net::Bot;
use Bot::Net::Mixin::Bot::IRC;

Bot::Net::Test->start_server('ServerBotted');

on bot connected => run {
    for ( 1 .. 26 ) {
        yield send_to => AtoZ => 'something';
    }
};

on bot message_to_me => run {
    my $event = get ARG0;
    my $alpha_expected = (recall('alpha') || 'A');

    is($event->sender_nick, 'AtoZ');
    is($event->message, $alpha_expected);

    remember alpha => ++$alpha_expected;

    if ($alpha_expected eq 'Z') {
        yield bot quit => 'Test finished.';
    }
};

# Startup the bot!
Bot::Net::Test->run_test;
