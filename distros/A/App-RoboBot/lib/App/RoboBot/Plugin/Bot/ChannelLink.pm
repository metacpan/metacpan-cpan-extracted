package App::RoboBot::Plugin::Bot::ChannelLink;
$App::RoboBot::Plugin::Bot::ChannelLink::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use Data::Dumper;
use App::RoboBot::Channel;
use App::RoboBot::Response;

extends 'App::RoboBot::Plugin';

=head1 bot.channellink

Allows for echoing messages across different channels, even across networks.

Linked channels require the bot to exist in both. Messages sent by users of one
channel will be echoed to the other by the bot. When possible (network features
permitting), the names of the original senders will be included in the echoed
output.

The linked channels do not need to be on the same network, but they must be
connected to by the same instance of the bot.

=cut

has '+name' => (
    default => 'Bot::ChannelLink',
);

has '+description' => (
    default => 'Allows for echoing messages across different channels, even across networks.',
);

has '+before_hook' => (
    default => 'echo_incoming',
);

has '+after_hook' => (
    default => 'echo_outgoing',
);

=head2 link-channels

=head3 Description

Links the current channel with the named channel, so that all messages
appearing in one are echoed to the other.

The link needs to be created only in one of the channels, as all links are
bi-directional. Echoed messages will be sent by the bot, but will be prefaced
with the string "<$network/$nick>" to indicate the original speaker and their
location. The channel name will assume a leading ``#`` in the event you do not
provide one (you cannot link one channel with a direct message).

For a list of networks and channels, refer to ``(network-list)`` and
``(channel-list)``, respectively.

=head3 Usage

<network> <channel>

=head3 Examples

    (link-channels freenode #mysecrethideout)

=head2 unlink-channels

=head3 Description

Removes the link with the named channel. As all links are bi-directional, this
function needs to be called only from one side to tear down the full link.

=head3 Usage

<network> <channel>

=head3 Examples

    (unlink-channels freenode #mysecrethideout)

=head2 channel-links

=head3 Description

Displays the current list of channels to which the current channel is linked.

=cut

has '+commands' => (
    default => sub {{
        'link-channels' => { method      => 'link_channels',
                             description => 'Link the current channel with the given channel, so that all messages appearing in one are echoed to the other. The link needs to be created only in one of the channels, as all links are bi-directional. Echoed messages will be sent by the bot, but will be prefaced with the string "<$network/$nick>" to indicate the original speaker and their location. The channel name will assume a leading "#" in the event you do not provide one (you cannot link one channel with a direct message). For a list of networks and channels, refer to (network-list) and (channel-list), respectively.',
                             usage       => '<network> <channel>',
                             example     => '"freenode" "#robobot"' },

        'unlink-channels' => { method => 'unlink_channels',
                               description => 'Removes a channel link (in both directions) that has been previously created with (link-channels).',
                               usage       => '<network> <channel>', },

        'channel-links' => { method      => 'show_links',
                             description => 'Shows the current list of channels to which the current channel is linked.', },
    }},
);

has 'links' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

sub init {
    my ($self, $bot) = @_;

    my $links = $bot->config->db->do(q{
        select l.*, c.network_id
        from channel_links l
            join channels c on (c.id = l.child_channel_id)
    });

    return unless $links;

    while ($links->next) {
        $self->links->{$links->{'parent_channel_id'}} = []
            unless exists $self->links->{$links->{'parent_channel_id'}};

        my $child_network = (grep { $_->id == $links->{'network_id'} } @{$bot->networks})[0];
        next unless defined $child_network;

        my $child_channel = App::RoboBot::Channel->find_by_id($bot, $links->{'child_channel_id'});
        next unless defined $child_channel;

        push(@{$self->links->{$links->{'parent_channel_id'}}},
            $child_channel
        );
    }
}

sub link_channels {
    my ($self, $message, $command, $rpl, $network, $channel) = @_;

    return unless defined $network && defined $channel;
    return unless $message->has_channel;

    $channel =~ s{^\#+}{}ogs;

    my $child = $self->bot->config->db->do(q{
        select n.id as network_id, c.id as channel_id,
            n.name as network_name, c.name as channel_name
        from networks n
            join channels c on (c.network_id = n.id)
        where lower(n.name) = lower(?) and lower(c.name) = lower(?)
    }, $network, $channel);

    unless ($child && $child->next) {
        $message->response->raise('Could not find a channel with the name %s on the %s network. Please check (network-list) and (channel-list).',
            $channel, $network);
        return;
    }

    my $res = $self->bot->config->db->do(q{
        select *
        from channel_links
        where parent_channel_id = ? and child_channel_id = ?
    }, $message->channel->id, $child->{'channel_id'});

    if ($res && $res->next) {
        $message->response->raise('That channel has already been linked to this one.');
        return;
    }

    $res = $self->bot->config->db->do(q{
        insert into channel_links ??? returning *
    }, [{
        parent_channel_id => $message->channel->id,
        child_channel_id  => $child->{'channel_id'},
        created_by        => $message->sender->id,
    }, {
        parent_channel_id => $child->{'channel_id'},
        child_channel_id  => $message->channel->id,
        created_by        => $message->sender->id,
    }]);

    my $child_network = (grep { $_->id == $child->{'network_id'} } @{$self->bot->networks})[0];
    next unless defined $child_network;

    my $child_channel = (grep { $_->id == $child->{'channel_id'} } @{$child_network->channels})[0];
    next unless defined $child_channel;

    $self->links->{$message->channel->id} = [] unless exists $self->links->{$message->channel->id};
    push(@{$self->links->{$message->channel->id}}, $child_channel);

    $self->links->{$child_channel->id} = [] unless exists $self->links->{$child_channel->id};
    push(@{$self->links->{$child_channel->id}}, $message->channel);

    $message->response->push(sprintf('This channel has now been linked with %s on the %s network. All messages will be echoed between the two.',
        $child->{'channel_name'}, $child->{'network_name'}));
}

sub unlink_channels {
    my ($self, $message, $command, $rpl, $network, $channel) = @_;

    return unless defined $network && defined $channel;
    return unless $message->has_channel;

    $channel =~ s{^\#+}{}ogs;

    my $child = $self->bot->config->db->do(q{
        select n.id as network_id, c.id as channel_id,
            n.name as network_name, c.name as channel_name
        from networks n
            join channels c on (c.network_id = n.id)
            join channel_links l on (l.child_channel_id = c.id)
        where lower(n.name) = lower(?)
            and lower(c.name) = lower(?)
            and l.parent_channel_id = ?
    }, $network, $channel, $message->channel->id);

    unless ($child && $child->next) {
        $message->response->raise('Could not find a channel with the name %s on the %s network that is linked to the current channel. Please check (channel-links).',
            $channel, $network);
        return;
    }

    my $res = $self->bot->config->db->do(q{
        delete from channel_links
        where (parent_channel_id = ? and child_channel_id = ?)
            or (parent_channel_id = ? and child_channel_id = ?)
    }, $message->channel->id, $child->{'channel_id'},
        $child->{'channel_id'}, $message->channel->id);

    if (exists $self->links->{$message->channnel->id}) {
        $self->links->{$message->channel->id} = [
            grep { $_->id != $child->{'channel_id'} } @{$self->links->{$message->channel->id}}
        ];
    }

    if (exists $self->links->{$child->{'channel_id'}}) {
        $self->links->{$child->{'channel_id'}} = [
            grep { $_->id != $message->channel->id } @{$self->links->{$child->{'channel_id'}}}
        ];
    }

    $message->response->push(sprintf('Channel %s on the %s network has been unlinked from this one.',
        $child->{'channel_name'}, $child->{'network_name'}));
    return;
}

sub show_links {
    my ($self, $message, $command, $rpl) = @_;

    return unless $message->has_channel;

    if (exists $self->links->{$message->channel->id}) {
        my $links = $self->links->{$message->channel->id};

        $message->response->push('This channel is linked to the following other channels:');
        foreach my $ch (sort { $a->network->name cmp $b->network->name || $a->name cmp $b->name } @{$links}) {
            $message->response->push(sprintf('Network: %s, Channel: %s', $ch->network->name, $ch->name));
        }
    } else {
        $message->response->push('This channel has no links to other channels. Use (link-channels) to create one.');
    }

    return;
}

sub link_echo {
    my ($self, $message, $text) = @_;

    foreach my $channel (@{$self->links->{$message->channel->id}}) {
        my $response = App::RoboBot::Response->new(
            network => $channel->network,
            channel => $channel,
            bot     => $self->bot,
        );

        $response->push($text);
        $response->send;
    }
}

sub echo_incoming {
    my ($self, $message) = @_;

    return unless $message->has_channel;
    return unless exists $self->links->{$message->channel->id};

    my $msg = sprintf('<%s> %s', $message->sender->name, $message->raw);

    $self->link_echo($message, $msg);
}

sub echo_outgoing {
    my ($self, $message) = @_;

    return unless $message->response->has_content;
    return unless $message->response->has_channel;
    return unless exists $self->links->{$message->response->channel->id};

    foreach my $line (@{$message->response->content}) {
        my $msg = sprintf('<%s> %s', $message->response->channel->network->nick->name, $line);

        $self->link_echo($message->response, $msg);
    }
}

__PACKAGE__->meta->make_immutable;

1;
