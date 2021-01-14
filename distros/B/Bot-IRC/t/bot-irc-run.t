use Test2::V0;
use Test::Output;
use Bot::IRC;

my $socket = mock 'IO::Socket::IP' => (
    override => [
        new   => sub { return bless( {}, shift ) },
        print => sub {},
    ],
);

my $device = mock 'Daemon::Device' => (
    override => [
        new      => sub { return bless( {}, shift ) },
        run      => sub {},
        ppid     => sub { return 42 },
        children => sub { return [ 1024, 1138 ] },
        message  => sub {},
    ],
);

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
ok( lives { $bot = Bot::IRC->new(
    %$settings,
) }, 'Bot::IRC->new(@config)' ) or note $@;

ok( lives { $bot->run }, 'Bot::IRC->run' ) or note $@;

stdout_like(
    sub { $bot->say( qw( line0 line1 ) ) },
    qr/\[[^\]]+\] <<< line0\n\[[^\]]+\] <<< line1\n/ms,
    '$bot->say',
);

stdout_like(
    sub { $bot->msg( '#test', 'Message.' ) },
    qr/\[[^\]]+\] <<< PRIVMSG #test :Message.\n/ms,
    '$bot->msg',
);

like(
    warning { $bot->reply('Message.') },
    qr/Didn't have a target to send reply to/,
    '$bot->reply without forum',
);

stdout_like(
    sub { $bot->nick('new') },
    qr/\[[^\]]+\] <<< NICK new\n/ms,
    '$bot->nick',
);

is(
    $bot->list( ', ', 'and', 'Alpha', 'Beta', 'Delta', 'Gamma' ),
    'Alpha, Beta, Delta, and Gamma',
    '$bot->list long',
);

is(
    $bot->list( ', ', 'and', 'Alpha', 'Beta' ),
    'Alpha and Beta',
    '$bot->list short',
);

done_testing;
