package TestBot::SingleSendJoin;

use AnyEvent;
use Bot::Backbone;

has token => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has channel => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
);

has ready => (
    is          => 'ro',
    required    => 1,
);

has say_code => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has during_init => (
    is          => 'rw',
    isa         => 'Bool',
);

has _t => (
    is          => 'rw',
);

override run => sub {
    my $self = shift;

    my $joined = AnyEvent->condvar;

    service slack_chat => (
        service => 'SlackChat',
        token   => $self->token,
        on_channel_joined => sub {
            my ($slack, $id, $name, $init) = @_;

            return unless $id eq $self->channel;

            $self->during_init($init);

            service test_group => (
                service    => 'GroupChat',
                chat       => 'slack_chat',
                group      => $self->channel,
            );

            $joined->send;
        },
    );

    super;

    # We need to wait until Bot::Backbone has had a chance to instantiate the
    # service before we can work with it.
    $joined->cb(sub {
        $self->_t(
            AnyEvent->timer(after => 1, cb => sub {
                $self->ready->recv;

                #warn "# SENDING\n";
                $self->get_service('test_group')->send_message({
                    text => "!hello " . $self->say_code,
                });

                $self->shutdown;
            })
        );
    });
};

1;
