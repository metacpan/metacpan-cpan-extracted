package App::RoboBot::Network::Mattermost;
$App::RoboBot::Network::Mattermost::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use AnyEvent;
use AnyEvent::Mattermost;

use Data::Dumper;
use JSON;
use LWP::Simple;
use Try::Tiny;

use App::RoboBot::Channel;
use App::RoboBot::Nick;

extends 'App::RoboBot::Network';

has '+type' => (
    default => 'mattermost',
);

has 'server' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'team' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'email' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'password' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'client' => (
    is     => 'rw',
    isa    => 'AnyEvent::Mattermost',
    traits => [qw( SetOnce )],
);

sub BUILD {
    my ($self) = @_;

    $self->client(AnyEvent::Mattermost->new(
        $self->server, $self->team, $self->email, $self->password
    ));

    $self->client->on( 'posted' => sub {
        my ($cl, $msg) = @_;
        $self->handle_message($msg);
    });
}

sub connect {
    my ($self) = @_;

    $self->client->start;
}

sub disconnect {
    my ($self) = @_;

    $self->client->close;
}

sub reconnect {
    my ($self) = @_;

    $self->disconnect && $self->connect;
}

sub send {
    my ($self, $response) = @_;

    unless ($response->has_channel) {
        $response->clear_content;
        return;
    }

    my $output = join(($response->collapsible ? ' ' : "\n"), @{$response->content});

    # For now, set an arbitrary limit on responses of 4K (even with multibyte
    # characters, that should keep us safely below the Mattermost API limit).
    if (length($output) > 4096) {
        $output = substr($output, 0, 4096) .
            "\n\n... Output truncated ...";
    }

    $self->client->send({
        channel => $response->channel->name,
        message => $output,
    });

    $response->clear_content;

    return;
}

sub handle_message {
    my ($self, $msg) = @_;

    # Short circuit if this message doesn't have 'post' data.
    return unless defined $msg && ref($msg) eq 'HASH'
        && exists $msg->{'event'} && $msg->{'event'} eq 'posted'
        && exists $msg->{'data'} && ref($msg->{'data'}) eq 'HASH'
        && exists $msg->{'data'}{'post'} && length($msg->{'data'}{'post'}) > 0;

    my $post = try {
        decode_json($msg->{'data'}{'post'});
    } catch {
        return;
    };

    my $nick    = App::RoboBot::Nick->new(
        name      => $msg->{'data'}{'sender_name'},
        network   => $self,
        config    => $self->config,
        extradata => {
            team_id => $msg->{'team_id'},
            user_id => $msg->{'user_id'},
        },
    );
    my $channel = App::RoboBot::Channel->new(
        name      => $msg->{'data'}{'channel_display_name'},
        network   => $self,
        config    => $self->config,
        extradata => {
            team_id      => $msg->{'team_id'},
            channel_id   => $msg->{'channel_id'},
            channel_type => $msg->{'data'}{'channel_type'},
        },
    );

    return unless defined $nick && defined $channel;

    # Ignore our own messages (everything we post comes back over the wire as
    # a regular message.
    return if lc($nick->name) eq lc($self->nick->name);

    my $raw_msg = exists $post->{'message'} && defined $post->{'message'} ? $post->{'message'} : '';

    # Unescape a couple things
    $raw_msg =~ s{\&amp;}{&}g;
    $raw_msg =~ s{\&lt;}{<}g;
    $raw_msg =~ s{\&gt;}{>}g;

    my $message = App::RoboBot::Message->new(
        bot     => $self->bot,
        raw     => $raw_msg,
        network => $self,
        sender  => $nick,
        channel => $channel,
    );

    $message->process;
}

__PACKAGE__->meta->make_immutable;

1;
