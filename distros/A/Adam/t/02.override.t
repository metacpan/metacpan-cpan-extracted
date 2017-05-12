use Test::More;
use Test::Deep;
POE::Kernel->run;
use POE::Component::IRC::Qnet::State;
{

    package QnetBot;
    use Moses;
    use namespace::autoclean;

    sub _build__irc {
        POE::Component::IRC::Qnet::State->spawn(
            Nick     => $_[0]->get_nickname,
            Server   => $_[0]->get_server,
            Port     => $_[0]->get_port,
            Ircname  => $_[0]->get_nickname,
            Options  => $_[0]->get_poco_irc_options,
            Flood    => $_[0]->can_flood,
            Username => $_[0]->get_username,
            Password => $_[0]->get_password,
            %{ $_[0]->get_poco_irc_args },
        );
    }

}

my $bot = QnetBot->new();
is(
    ref $bot->irc,
    'POE::Component::IRC::Qnet::State',
    'override the subclass worked'
);
done_testing();
