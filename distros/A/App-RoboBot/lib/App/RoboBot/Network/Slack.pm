package App::RoboBot::Network::Slack;
$App::RoboBot::Network::Slack::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use AnyEvent;
use AnyEvent::SlackRTM;

use Data::Dumper;
use JSON;
use LWP::Simple;

use App::RoboBot::Channel;
use App::RoboBot::Message;
use App::RoboBot::Nick;

extends 'App::RoboBot::Network';

has '+type' => (
    default => 'slack',
);

has 'token' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'client' => (
    is     => 'rw',
    isa    => 'AnyEvent::SlackRTM',
    traits => [qw( SetOnce )],
);

has 'keepalive' => (
    is     => 'rw',
    traits => [qw( SetOnce )],
);

has 'ping_payload' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { { pong => 1 } },
);

has 'start_ts' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub { time() },
);

has 'profile_cache' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'channel_cache' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

sub BUILD {
    my ($self) = @_;

    $self->client(AnyEvent::SlackRTM->new(
        $self->token
    ));

    $self->client->on( 'hello' => sub {
        $self->keepalive(AnyEvent->timer(
            interval => 60,
            cb       => sub { $self->reconnect if $self->client->finished }
        ));
    });

    $self->client->on( 'message' => sub {
        my ($cl, $msg) = @_;
        $self->handle_message($msg);
    });
}

sub connect {
    my ($self) = @_;

    $self->log->info(sprintf('Connecting to Slack network %s.', $self->name));

    # Build our channel list so that things like channel linking will work.
    my $res = $self->bot->config->db->do(q{
        select id, name
        from channels
        where network_id = ?
        order by name asc
    }, $self->id);

    return unless $res;

    my @channels;

    while ($res->next) {
        # Do not include Slack DMs in the channel list.
        next if $res->{'name'} =~ m{^dm:};
        push(@channels, App::RoboBot::Channel->find_by_id($self->bot, $res->{'id'}));
    }

    $self->channels(\@channels);

    $self->log->debug('Channels loaded.');

    # Callbacks should be registered already in the BUILD method, so we just
    # need to start the client and have it connect to the Slack WebSocket API.
    $self->client->start;

    $self->log->debug('SlackRTM client started.');
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

    unless (exists $response->channel->extradata->{'slack_id'}) {
        $response->clear_content;
        return;
    }

    my $output = join(($response->collapsible ? ' ' : "\n"), @{$response->content});

    # For now, set an arbitrary limit on responses of 4K (SlackRTM says 16K,
    # which assuming absolute worst-case with wide characters would be 4K
    # glyphs, but even that seems really excesive for a chatbot).
    if (length($output) > 4096) {
        $output = substr($output, 0, 4096) .
            "\n\n... Output truncated ...";
    }

    $self->client->send({
        channel => $response->channel->extradata->{'slack_id'},
        type    => 'message',
        text    => $output,
    });

    $response->clear_content;

    return;
}

sub handle_message {
    my ($self, $msg) = @_;

    $self->log->debug('Received incoming message.');

    return unless exists $msg->{'ts'};
    return if int($msg->{'ts'}) <= $self->start_ts + 5;

    $self->log->debug('Message passed startup timestamp check.');

    # Short circuit if this isn't a 'message' type message.
    return unless defined $msg && ref($msg) eq 'HASH'
        && exists $msg->{'type'} && $msg->{'type'} eq 'message'
        && exists $msg->{'text'} && $msg->{'text'} =~ m{\w+};

    $self->log->debug('Message payload appears valid.');

    # Ignore messages which are hidden or have a subtype (these are generall
    # message edits or similar events).
    # TODO: Consider trapping message_edit subtypes and replacing log history?
    #       Most likely more work than it's worth, especially since it would
    #       require direct and special-snowflake interaction with a plugin.
    return if exists $msg->{'subtype'} && $msg->{'subtype'} =~ m{\w+};
    return if exists $msg->{'hidden'} && $msg->{'hidden'} == 1;

    $self->log->debug('Message has no subtype and is not hidden.');

    $self->log->debug(sprintf('Resolving nick for Slack ID %s.', $msg->{'user'}));
    my $nick    = $self->resolve_nick($msg->{'user'});

    $self->log->debug(sprintf('Resolving channel for Slack ID %s.', $msg->{'channel'}));
    my $channel = $self->resolve_channel($msg->{'channel'});

    return unless defined $nick && defined $channel;

    my $raw_msg = exists $msg->{'text'} && defined $msg->{'text'} ? $msg->{'text'} : '';

    # Remove brackets around URLs. Do alt-named ones first, then URL-only links.
    $raw_msg =~ s{<(http[^|>]+)\|[^>]+>}{$1}g;
    $raw_msg =~ s{<(http[^>]+)>}{$1}g;

    # Unescape a couple things from Slack.
    $raw_msg =~ s{\&amp;}{&}g;
    $raw_msg =~ s{\&lt;}{<}g;
    $raw_msg =~ s{\&gt;}{>}g;

    $self->log->debug('Raw message stripped of markup.');

    my ($message);

    eval {
        $message = App::RoboBot::Message->new(
            bot     => $self->bot,
            raw     => $raw_msg,
            network => $self,
            sender  => $nick,
            channel => $channel,
        );
    };

    return $self->log->fatal($@) if $@;

    $self->log->debug('Message object constructed, preparing to process.');

    $message->process;
}

sub resolve_channel {
    my ($self, $slack_id) = @_;

    return $self->channel_cache->{$slack_id} if exists $self->channel_cache->{$slack_id};

    my $channel;

    my $res = $self->bot->config->db->do(q{
        select id, name, extradata
        from channels
        where network_id = ? and extradata @> ?
    }, $self->id, encode_json({ slack_id => $slack_id }));

    if ($res && $res->next) {
        $channel = App::RoboBot::Channel->new(
            id          => $res->{'id'},
            name        => $res->{'name'},
            extradata   => decode_json($res->{'extradata'}),
            network     => $self,
            config      => $self->bot->config,
        );

        $self->channel_cache->{$slack_id} = $channel;
        return $channel;
    }

    my ($json, $chandata);

    # Slack has different API endpooints for channels and private groups, so
    # make sure we're using the right one based on the first character of the
    # identifier. And some, like direct messages, return fairly different data
    # structures, so each type should handle decoding and massaging their own.
    if (substr($slack_id, 0, 1) eq 'C') {
        $json = get('https://slack.com/api/channels.info?token=' . $self->token . '&channel=' . $slack_id);
        eval { $json = decode_json($json) };
        return if $@;

        return unless exists $json->{'ok'} && $json->{'ok'};
        return unless exists $json->{'channel'};
        $chandata = $json->{'channel'};
    } elsif (substr($slack_id, 0, 1) eq 'G') {
        $json = get('https://slack.com/api/groups.info?token=' . $self->token . '&channel=' . $slack_id);
        eval { $json = decode_json($json) };
        return if $@;

        return unless exists $json->{'ok'} && $json->{'ok'};
        return unless exists $json->{'group'};
        $chandata = $json->{'group'};
    } elsif (substr($slack_id, 0, 1) eq 'D') {
        # This was a direct message, which requires some additional handling.
        $json = get('https://slack.com/api/im.list?token=' . $self->token);
        eval { $json = decode_json($json) };
        return if $@;

        return unless exists $json->{'ok'} && $json->{'ok'};
        return unless exists $json->{'ims'} && ref($json->{'ims'}) eq 'ARRAY';

        $chandata = (grep { $_->{'id'} eq $slack_id } @{$json->{'ims'}})[0];
        return unless defined $chandata && ref($chandata) eq 'HASH';
        return unless exists $chandata->{'user'};
        return if $chandata->{'user'} eq 'USLACKBOT';

        my $nick = $self->resolve_nick($chandata->{'user'});

        # Mock up a channel name for the DM history with this user.
        $chandata->{'name'} = sprintf('dm:%s', $nick->name);
    } else {
        # Not a group or a channel or a direct message, bail out.
        return;
    }

    return unless defined $chandata && ref($chandata) eq 'HASH';

    $res = $self->bot->config->db->do(q{
        select id, name, extradata
        from channels
        where network_id = ? and lower(name) = lower(?)
    }, $self->id, $chandata->{'name'});

    if ($res && $res->next) {
        $res->{'extradata'} = decode_json($res->{'extradata'});
        $res->{'extradata'}{'slack_id'} = $slack_id;

        $self->bot->config->db->do(q{
            update channels
            set extradata = ?,
                updated_at = now() where id = ?
        }, encode_json($res->{'extradata'}), $res->{'id'});

        $channel = App::RoboBot::Channel->new(
            id          => $res->{'id'},
            name        => $res->{'name'},
            extradata   => $res->{'extradata'},
            network     => $self,
            config      => $self->bot->config,
        );

        $self->channel_cache->{$slack_id} = $channel;
        return $channel;
    }

    $res = $self->bot->config->db->do(q{
        insert into channels ??? returning id, name, extradata
    }, { name       => $chandata->{'name'},
         network_id => $self->id,
         extradata  => encode_json({ slack_id => $slack_id }),
    });

    if ($res && $res->next) {
        $channel = App::RoboBot::Channel->new(
            id          => $res->{'id'},
            name        => $res->{'name'},
            extradata   => decode_json($res->{'extradata'}),
            network     => $self,
            config      => $self->bot->config,
        );

        $self->channel_cache->{$slack_id} = $channel;
        return $channel;
    }

    return;
}

sub resolve_nick {
    my ($self, $slack_id) = @_;

    # User profile already in our cache (we've seen or created it during this
    # session, so simply return what we have.
    return $self->profile_cache->{$slack_id} if exists $self->profile_cache->{$slack_id};

    # Check database for a nick with this Slack ID. If found, instantiate a new
    # App::RoboBot::Nick object with the data, cache it, and return.
    my $nick;

    my $res = $self->bot->config->db->do(q{
        select id, name, extradata
        from nicks where extradata @> ?
    }, encode_json({ slack_id => $slack_id }));

    if ($res && $res->next) {
        $nick = App::RoboBot::Nick->new(
            id        => $res->{'id'},
            name      => $res->{'name'},
            extradata => decode_json($res->{'extradata'}),
            network   => $self,
            config    => $self->config,
        );

        $self->profile_cache->{$slack_id} = $nick;
        return $nick;
    }

    # We haven't encountered this nick before, so we need to query the SlackAPI
    # for their handle and other profile details.
    my $json = get('https://slack.com/api/users.info?token=' . $self->token . '&user=' . $slack_id);
    return unless defined $json;

    my $userdata = decode_json($json);
    return unless defined $userdata && ref($userdata) eq 'HASH' && exists $userdata->{'ok'} && $userdata->{'ok'};

    # Now that we know their handle, we can see if we already have a record for
    # that. If so, we update it to include their Slack ID, drop it in our cache,
    # and return the nick object.
    $res = $self->bot->config->db->do(q{
        select id, name, extradata
        from nicks
        where lower(name) = lower(?)
    }, $userdata->{'user'}{'name'});

    if ($res && $res->next) {
        $res->{'extradata'} = decode_json($res->{'extradata'});
        $res->{'extradata'}{'slack_id'} = $slack_id;
        $res->{'extradata'}{'full_name'} = $userdata->{'user'}{'profile'}{'real_name'} if exists $userdata->{'user'}{'profile'}{'real_name'};

        $self->bot->config->db->do(q{
            update nicks
            set extradata = ?,
                updated_at = now()
            where id = ?
        }, encode_json($res->{'extradata'}), $res->{'id'});

        $nick = App::RoboBot::Nick->new(
            id        => $res->{'id'},
            name      => $res->{'name'},
            extradata => $res->{'extradata'},
            network   => $self,
            config    => $self->bot->config,
        );

        $self->profile_cache->{$slack_id} = $nick;
        return $nick;
    }

    # And finally, we've had no luck finding any matches, so we assume that the
    # nick is totally new to us. Create a new record, cache that, and return.
    my $extra = { slack_id => $slack_id };
    $extra->{'full_name'} = $userdata->{'user'}{'profile'}{'real_name'} if exists $userdata->{'user'}{'profile'}{'real_name'};

    $res = $self->bot->config->db->do(q{
        insert into nicks ??? returning id, name, extradata
    }, { name      => $userdata->{'user'}{'name'},
         extradata => encode_json($extra),
    });

    if ($res && $res->next) {
        $nick = App::RoboBot::Nick->new(
            id        => $res->{'id'},
            name      => $res->{'name'},
            extradata => decode_json($res->{'extradata'}),
            network   => $self,
            config    => $self->bot->config,
        );

        $self->profile_cache->{$slack_id} = $nick;
        return $nick;
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;
