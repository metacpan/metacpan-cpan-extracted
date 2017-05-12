package TestBot::SingleSend;

use Bot::Backbone;

has token => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has ready => (
    is          => 'ro',
    required    => 1,
);

has channel => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
);

has say_code => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

override run => sub {
    my $self = shift;

    service slack_chat => (
        service => 'SlackChat',
        token   => $self->token,
    );

    service test_group => (
        service    => 'GroupChat',
        chat       => 'slack_chat',
        group      => $self->channel,
    );

    __PACKAGE__->meta->make_immutable;

    super;

    $self->ready->recv;

    #warn "# SENDING\n";
    $self->get_service('test_group')->send_message({
        text => "!hello " . $self->say_code,
    });

    $self->shutdown;
};

1;
