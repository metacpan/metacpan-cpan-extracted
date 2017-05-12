package TestBot::SingleRecvJoin;

use Bot::Backbone;

has token => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has ready => (
    is         => 'ro',
    required   => 1,
);

has done => (
    is         => 'ro',
    required   => 1,
);

has invited => (
    is         => 'ro',
    predicate  => 'has_invited',
);

has channel => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
);

dispatcher 'hello_dispatch' => as {
    command '!hello' => given_parameters {
        parameter code => ( match => qr/.*/ );
    } run_this_method 'store_code';
};

has saw_code => (
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_code',
);

has during_init => (
    is          => 'rw',
    isa         => 'Bool',
);

sub store_code {
    my ($self, $message) = @_;

    my $code = $message->parameters->{code};

    if ($self->has_code) {
        die "code seen twice";
    }
    else {
        $self->saw_code($code);
        $self->shutdown;

        #warn "# DONE\n";
        $self->done->send;
    }
}

override run => sub {
    my $self = shift;

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
                dispatcher => 'hello_dispatch',
            );

            #warn "# READY\n";
            $self->ready->send;
            $self->invited->send if $self->has_invited;
        },
    );

    super;
};

1;
