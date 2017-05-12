use Test::More;
use Test::Deep;
POE::Kernel->run;

{

    package SampleBot;
    use Moses;
    use namespace::autoclean;

    server 'irc.perl.org';
    nickname 'sample-bot';
    channels '#bots';

    has message => (
        isa     => 'Str',
        is      => 'rw',
        default => 'Hello',
    );

    event irc_bot_addressed => sub {
        my ( $self, $nickstr, $channel, $msg ) = @_[ OBJECT, ARG0, ARG1, ARG2 ];
        my ($nick) = split /!/, $nickstr;
        $self->privmsg( $channel => "$nick: ${ \$self->message }" );
    };

}

ok( my $bot = SampleBot->new(), 'new bot' );
is( $bot->get_server,   'irc.perl.org', 'right server' );
is( $bot->get_nickname, 'sample-bot',   'right nick' );
is( $bot->nick,         $bot->get_nickname, 'nick alias works' );
is_deeply( scalar $bot->get_channels, ['#bots'], 'right channels' );

done_testing();
