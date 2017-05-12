package Bot::Backbone::Service::TestChat;

use v5.10;
use Bot::Backbone::Service;

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::Dispatch
    Bot::Backbone::Service::Role::BareMetalChat
);

use Bot::Backbone::Identity;
use Bot::Backbone::Message;

has mq => (
    is          => 'rw',
    isa         => 'ArrayRef[HashRef]',
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        'put'      => 'push',
        'mq_count' => 'count',
    },
);

sub initialize { }

sub dispatch {
    my ($self, %params) = @_;

    my %defaults = (
        from => {
            username => 'test',
            nickname => 'Test',
            me       => '',
        },
        to => {
            username => 'testbot',
            nickname => 'Test Bot',
            me       => 1,
        },
        group => undef,
    );

    my %merged = (%defaults, %params);

    my $message = Bot::Backbone::Message->new({
        chat  => $self,
        from  => Bot::Backbone::Identity->new($merged{from}),
        to    => Bot::Backbone::Identity->new($merged{to}),
        group => $merged{group},
        text  => $merged{text},
    });

    $self->resend_message($message);
    $self->dispatch_message($message);
}

sub send_message {
    my ($self, $params) = @_;

    $self->put({
        %$params,
        time => time,
    });
}

__PACKAGE__->meta->make_immutable;
