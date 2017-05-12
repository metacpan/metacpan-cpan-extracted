#!/usr/bin/env perl
use Test::More;
use Moses::Declare;
POE::Kernel->run;
bot SampleBot {
    server 'irc.perl.org';
    channels '#bots';
}

ok( my $bot = SampleBot->new(), 'new bot' );
is( $bot->get_server,   'irc.perl.org',     'right server' );
is( $bot->get_nickname, 'SampleBot',        'right nick' );
is( $bot->nick,         $bot->get_nickname, 'nick alias works' );
is_deeply( scalar $bot->get_channels, ['#bots'], 'right channels' );

plugin SamplePlugin {
    sub S_bot_addressed { }
}

ok( my $plugin = SamplePlugin->new(bot => $bot), 'new plugin' );
is_deeply( $plugin->_events, ['S_bot_addressed'], 'right events' );

done_testing;
