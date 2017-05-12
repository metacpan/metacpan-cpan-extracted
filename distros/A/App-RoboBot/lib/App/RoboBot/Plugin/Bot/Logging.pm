package App::RoboBot::Plugin::Bot::Logging;
$App::RoboBot::Plugin::Bot::Logging::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use Number::Format;
use Term::ExtendedColor qw( fg bold );

extends 'App::RoboBot::Plugin';

=head1 bot.logging

Provides basic message logging and recall capabilities.

In addition to the exported functions, this module installs both pre and post
hooks into the message processing pipeline for the purposes of logging all
incoming and outgoing messages on all connected networks.

Logging functionality is enabled by default wherever the bot is connected, but
it may be disabled per-channel using ``(disable-logging)`` and re-enabled by
using ``(enable-logging)``. Any messages that occurred while logging was
disabled are lost permanently, and any functions which require logging to be
active will fail when it is disabled.

=cut

has '+name' => (
    default => 'Bot::Logging',
);

has '+description' => (
    default => 'Provides basic message logging and recall capabilities.',
);

has '+before_hook' => (
    default => 'log_incoming',
);

has '+after_hook' => (
    default => 'log_outgoing',
);

=head2 last

=head3 Description

Returns a previous message uttered in the current channel. The ``step`` is how
many messages backward to count, with ``1`` assumed and being the most recent
message available. A nick is optional, but if provided will limit the messages
considered to only those sent by the named user.

By default, any messages which had S-Expressions in them are skipped, but those
may be included by adding the ``:include-expressions`` symbol.

=head3 Usage

[:include-expressions] [<step>] [<nick>]

=head3 Examples

    (last)
    (last :include-expressions)
    (last 10 Beauford)

=head2 seen

=head3 Description

Reports the last time the given nick was observed saying something in any
channel that has logging enabled.

=head3 Usage

<nick>

=head3 Examples

    :emphasize-lines: 2,3

    (seen Beauford)
    Beauford was last observed on Thursday, April 28th, 2016 at 3:23 PM speaking in #robobot on the freenode network. Their last words were:
    <Beauford> This is a fake message for demonstration purposes only.

=head2 search

=head3 Description

Searches scrollback in the current channel for anything that matches
``pattern`` which may be a simple string or a regular expression. Returns the
most recent matching entry.

=head3 Usage

<pattern>

=head2 disable-logging

=head3 Description

Disables logging any activity in the current channel until the
``(enable-logging)`` function is called.

Note that logging is enabled by default. Explicit disabling/enabling of logging
is on a per-channel basis.

=head2 enable-logging

=head3 Description

Enables logging activity in the current channel if it had been previously
turned off via ``(disable-logging)``. Does nothing is logging is already active
in the current channel.

Note that logging is enabled by default. Explicit disabling/enabling of logging
is on a per-channel basis.

=cut

has '+commands' => (
    default => sub {{
        'last' => { method      => 'show_last',
                    description => 'Returns a previous message from the given nick(s). The <step> is how many messages backward to count, with "1" assumed and being the most recent message available. Nick is optional, and if ommitted the caller is assumed. By default, any messages which had S-Expressions in them are skipped.',
                    usage       => '[:include-expressions] [<step>] [<nick>]' },

        'seen' => { method      => 'last_seen',
                    description => 'Reports the last time the given nick was observed saying something in any channel.',
                    usage       => '<nick>' },

        'search' => { method      => 'log_search',
                      description => 'Searches scrollback in the current channel for anything that matches <pattern>, which may be a simple string or a regular expression. Returns the most recent matching entry.',
                      usage       => '<pattern>' },

        'disable-logging' => { method      => 'log_disable',
                               description => 'Disables logging any activity in the current channel until the (enable-logging) function is called.' },

        'enable-logging' => { method      => 'log_enable',
                              description => 'Enables logging activity in the current channel if it had been previously turned off via (disable-logging).' },
    }},
);

sub log_disable {
    my ($self, $message, $command, $rpl) = @_;

    $self->log->info(sprintf('%s has requested logging be disabled on %s for network %s.',
        $message->sender->name, ($message->has_channel ? $message->channel->name : '-'), $message->network->name));

    if ($message->channel->log_enabled) {
        if ($message->channel->disable_logging) {
            $message->response->push('Logging has now been disabled for this channel. No messages will be saved and any functions which interact with logging features will fail.');
        } else {
            $message->response->raise('Logging could not be disabled. Please try again.');
        }
    } else {
        $message->response->push('This channel is already unlogged. No changes made.');
    }

    return;
}

sub log_enable {
    my ($self, $message, $command, $rpl) = @_;

    $self->log->info(sprintf('%s has requested logging be enabled on %s for network %s.',
        $message->sender->name, ($message->has_channel ? $message->channel->name : '-'), $message->network->name));

    return unless $message->has_channel;

    if ($message->channel->log_enabled) {
        $self->log->warn(sprintf('Logging already enabled for %s on network %s.', $message->channel->name, $message->network->name));
        $message->response->push('This channel is already being logged. No changes made.');
    } else {
        if ($message->channel->enable_logging) {
            $self->log->debug(sprintf('Logging for %s on network %s now enabled.', $message->channel->name, $message->network->name));
            $message->response->push('Logging has now been enabled for this channel.');
        } else {
            $self->log->error(sprintf('Logging could not be enabled for %s on network %s.', $message->channel->name, $message->network->name));
            $message->response->raise('Logging could not be enabled. Please try again.');
        }
    }

    return;
}

sub log_search {
    my ($self, $message, $command, $rpl, $pattern) = @_;

    return unless $message->has_channel;

    if ( ! $message->channel->log_enabled) {
        $self->log->warn(sprintf('Log search attempted for %s on network %s, but logging is disabled. Rejecting search request.',
            $message->channel->name, $message->network->name));
        $message->response->raise('This channel is unlogged. You cannot retrieve channel history here.');
        return;
    }

    unless (defined $pattern && $pattern =~ m{.+}) {
        $message->response->raise('Must provide a pattern to search.');
        return;
    }

    my $res = $self->bot->config->db->do(q{
        select n.name, l.message, to_char(l.posted_at, 'YYYY-MM-DD HH24:MI') as posted_at
        from logger_log l
            join channels c on (c.id = l.channel_id)
            join nicks n on (n.id = l.nick_id)
        where c.id = ?
            and l.message ~* ?
            and not l.has_expression
        order by l.posted_at desc
        limit 1
    }, $message->channel->id, $pattern);

    unless ($res && $res->next) {
        $message->response->raise('No matching messages were found.');
        return;
    }

    $message->response->push(sprintf('[%s] <%s> %s', $res->{'posted_at'}, $res->{'name'}, $res->{'message'}));
    return;
}

sub last_seen {
    my ($self, $message, $command, $rpl, $nick) = @_;

    return unless $message->has_channel;

    if ( ! $message->channel->log_enabled) {
        $self->log->warn(sprintf('Last-seen lookup attempted for %s on network %s for nick %s, but logging is disabled. Rejecting request.',
            $message->channel->name, $message->network->name, $nick));
        $message->response->raise('This channel is unlogged. You cannot retrieve channel history here.');
        return;
    }

    my $res = $self->bot->config->db->do(q{
        select id, name
        from nicks
        where lower(name) = lower(?)
    }, $nick);

    if ($res && $res->next) {
        $res = $self->bot->config->db->do(q{
            select to_char(l.posted_at, 'on FMDay, FMMonth FMDDth, YYYY at FMHH:MI PM') as last_seen,
                n.name, c.name as channel_name, nt.name as network_name, l.message
            from logger_log l
                join nicks n on (n.id = l.nick_id)
                join channels c on (c.id = l.channel_id)
                join networks nt on (nt.id = c.network_id)
            where l.nick_id = ?
                and c.log_enabled
            order by l.posted_at desc
            limit 1
        }, $res->{'id'});

        if ($res && $res->next) {
            $message->response->push(sprintf('%s was last observed %s speaking in %s on the %s network. Their last words were:',
                $res->{'name'}, $res->{'last_seen'}, $res->{'channel_name'}, $res->{'network_name'}));
            $message->response->push(sprintf('<%s> %s', $res->{'name'}, $res->{'message'}));
        } else {
            $message->response->raise(sprintf('The nick %s is known to me, but I cannot seem to find a message from them in my logs.', $nick));
        }
    } else {
        $message->response->raise(sprintf('I do not appear to have ever seen the nick: %s', $nick));
    }

    return;
}

sub show_last {
    my ($self, $message, $command, $rpl, @args) = @_;

    if ( ! $message->channel->log_enabled) {
        $message->response->raise('This channel is unlogged. You cannot retrieve channel history here.');
        return;
    }

    my $include_expressions = 0;
    my $step = 1;
    my ($nick, $nick_id) = ($message->sender->name, $message->sender->id);

    my ($res);

    if (@args && @args > 0 && lc($args[0]) eq ':include-expressions') {
        shift(@args);
        $include_expressions = 1;
    }

    if (@args && @args > 0 && $args[0] =~ m{^\d+$}o) {
        $step = shift(@args);
    }

    if (@args && @args > 0) {
        $res = $self->bot->config->db->do(q{
            select id, name
            from nicks
            where lower(name) = lower(?)
        }, $args[0]);

        if ($res && $res->next) {
            ($nick_id, $nick) = ($res->{'id'}, $res->{'name'});
        } else {
            $message->response->raise(sprintf('Could not locate the nick: %s', $args[0]));
            return;
        }
    }

    # prevent offset from ever being less than 0
    $step = 1 unless $step > 1;

    $res = $self->bot->config->db->do(q{
        select n.name, l.message
        from logger_log l
            join nicks n on (n.id = l.nick_id)
        where n.id = ? and l.channel_id = ?
            and has_expression = ?
            and l.posted_at < ?
        order by l.posted_at desc
        limit 1 offset ?
    }, $nick_id, $message->channel->id, ($include_expressions ? 't' : 'f'), $message->timestamp->iso8601(), $step - 1);

    if ($res && $res->next) {
        return sprintf('<%s> %s', $res->{'name'}, $res->{'message'});
    } else {
        $message->response->raise('Could not locate a message in this channel for the nick: %s', $nick);
        return;
    }
}

sub log_incoming {
    my ($self, $message) = @_;

    if ($message->has_channel && $message->channel->log_enabled) {
        $self->bot->config->db->do(q{
            insert into logger_log ???
        }, {
            channel_id     => $message->channel->id,
            nick_id        => $message->sender->id,
            message        => $message->raw,
            has_expression => ($message->has_expression ? 't' : 'f'),
            posted_at      => $message->timestamp->iso8601(),
        });
    }

    my $msg_logger = $self->bot->logger('msg.rx');
    $msg_logger->info(sprintf('(%s/%s) <%s> %s', $message->network->name,
        ($message->has_channel ? $message->channel->name : '-'),
        $message->sender->name, $message->raw));
}

sub log_outgoing {
    my ($self, $message) = @_;

    return unless $message->response->has_content;

    if ($message->response->has_channel && $message->channel->log_enabled) {
        $self->bot->config->db->do(q{
            insert into logger_log ???
        }, [map {{
            channel_id => $message->response->channel->id,
            nick_id    => $message->network->nick->id,
            message    => $_,
        }} @{$message->response->content}] );
    }

    my $msg_logger = $self->bot->logger('msg.tx');

    foreach my $line (@{$message->response->content}) {
        $msg_logger->info(sprintf('(%s/%s) <%s> %s', $message->network->name,
            ($message->response->has_channel ? $message->response->channel->name : '-'),
            $message->network->nick->name, $line));
    }
}

__PACKAGE__->meta->make_immutable;

1;
