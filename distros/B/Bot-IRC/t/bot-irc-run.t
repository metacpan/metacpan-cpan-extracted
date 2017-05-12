use strict;
use warnings;

use Test::Most;
use Test::MockModule;
use Test::Output;

my $socket = Test::MockModule->new('IO::Socket::INET');
$socket->mock( new => sub {
    return bless( {}, shift );
} );
$socket->mock( print => sub {} );

my $device = Test::MockModule->new('Daemon::Device');
$device->mock( new => sub {
    return bless( {}, shift );
} );
$device->mock( run => sub {} );
$device->mock( ppid => sub { return 42 } );
$device->mock( children => sub { return [ 1024, 1138 ] } );
$device->mock( message => sub {} );

use constant MODULE => 'Bot::IRC';

BEGIN { use_ok(MODULE); }

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
    },
};

my $bot;
lives_ok( sub { $bot = MODULE->new(
    %$settings,
) }, MODULE . '->new(@config)' );

lives_ok( sub { $bot->run }, MODULE . '->run' );

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

warning_like(
    sub { $bot->reply('Message.') },
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
