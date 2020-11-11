use strict;
use warnings;

use Test::Lib;
use Test::Most;

use constant MODULE => 'Bot::IRC';

BEGIN { use_ok(MODULE); }
require_ok(MODULE);

throws_ok( sub { MODULE->new }, qr|connect/server not provided|, MODULE . '->new dies' );
lives_ok( sub { MODULE->new(
    connect => { server => 'irc.perl.org' }
) }, MODULE . '->new( connect => { server => $server } )' );

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

lives_ok( sub { $bot = MODULE->new(%$settings) }, MODULE . '->new(@config)' );

throws_ok( sub { $bot = MODULE->new(
    %$settings,
    plugins => ['MissingPlugin'],
) }, qr/Unable to find or properly load/, MODULE . '->new(@config) + missing plugin' );

lives_ok( sub { $bot = MODULE->new(
    %$settings,
    plugins => ['SimpleTestPlugin'],
) }, MODULE . '->new(@config) + empty plugin' );

lives_ok( sub {
    $bot->reload('SimpleTestPlugin')
}, MODULE . '->reload SimpleTestPlugin' );

lives_ok( sub {
    $bot->hook( {}, sub {}, { priority => 50 } )
}, MODULE . '->hook' );

lives_ok( sub {
    $bot->hooks(
        [ {}, sub {} ],
        [ {}, sub {} ],
    )
}, MODULE . '->hooks' );

lives_ok( sub {
    $bot->helps( term => 'Description.', term2 => 'Description two.' )
}, MODULE . '->hooks' );

lives_ok( sub {
    $bot->tick( 10, sub {} )
}, MODULE . '->tick' );

lives_ok( sub {
    $bot->ticks(
        [ 10, sub {} ],
        [ 10, sub {} ],
    )
}, MODULE . '->ticks' );

lives_ok( sub {
    $bot->subs(
        name0 => sub {},
        name1 => sub {},
    )
}, MODULE . '->ticks' );

lives_ok( sub {
    $bot->register( qw( Alpha Beta Delta ) )
}, MODULE . '->ticks' );

done_testing;
