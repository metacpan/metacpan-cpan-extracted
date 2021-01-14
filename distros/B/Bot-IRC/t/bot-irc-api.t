use Test2::V0;
use Test::Lib;
use Bot::IRC;

like( dies { Bot::IRC->new }, qr|connect/server not provided|, 'Bot::IRC->new dies' );
ok( lives { Bot::IRC->new(
    connect => { server => 'irc.perl.org' }
) }, 'Bot::IRC->new( connect => { server => $server } )' ) or note $@;

my $settings = {
    spawn  => 3,
    daemon => {
        name        => 'bot',
        lsb_sdesc   => 'IRC Bot',
        pid_file    => 'bot.pid',
        stderr_file => 'bot.err',
        stdout_file => 'bot.log',
    },
    connect => {
        server => 'irc.perl.org',
        port   => '6667',
        nick   => 'bot',
        name   => 'Yet Another IRC Bot',
        join   => [ '#test', '#perl' ],
        ssl    => 0,
        ipv6   => 0,
    },
};

my $bot;

ok( lives { $bot = Bot::IRC->new(%$settings) }, 'Bot::IRC->new(@config)' ) or note $@;

like( dies { $bot = Bot::IRC->new(
    %$settings,
    plugins => ['MissingPlugin'],
) }, qr/Unable to find or properly load/, 'Bot::IRC->new(@config) + missing plugin' );

ok( lives { $bot = Bot::IRC->new(
    %$settings,
    plugins => ['SimpleTestPlugin'],
) }, 'Bot::IRC->new(@config) + empty plugin' ) or note $@;

ok( lives {
    $bot->reload('SimpleTestPlugin')
}, 'Bot::IRC->reload SimpleTestPlugin' ) or note $@;

ok( lives {
    $bot->hook( {}, sub {}, { priority => 50 } )
}, 'Bot::IRC->hook' ) or note $@;

ok( lives {
    $bot->hooks(
        [ {}, sub {} ],
        [ {}, sub {} ],
    )
}, 'Bot::IRC->hooks' ) or note $@;

ok( lives {
    $bot->helps( term => 'Description.', term2 => 'Description two.' )
}, 'Bot::IRC->hooks' ) or note $@;

ok( lives {
    $bot->tick( 10, sub {} )
}, 'Bot::IRC->tick' ) or note $@;

ok( lives {
    $bot->ticks(
        [ 10, sub {} ],
        [ 10, sub {} ],
    )
}, 'Bot::IRC->ticks' ) or note $@;

ok( lives {
    $bot->subs(
        name0 => sub {},
        name1 => sub {},
    )
}, 'Bot::IRC->ticks' ) or note $@;

ok( lives {
    $bot->register( qw( Alpha Beta Delta ) )
}, 'Bot::IRC->ticks' ) or note $@;

done_testing;
