package App::RoboBot::Plugin::Bot::Autoreply;
$App::RoboBot::Plugin::Bot::Autoreply::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use Data::Dumper;
use App::RoboBot::Parser;
use Scalar::Util qw( blessed );
use Try::Tiny;

extends 'App::RoboBot::Plugin';

=head1 bot.autoreply

Provides functions which allow the creation of rules to be evaluated against
incoming messages (and their metadata) and potentially trigger the execution of
expressions in response when those conditions are met.

=cut

has '+name' => (
    default => 'Bot::Autoreply',
);

has '+description' => (
    default => 'Provides functions which allow for conditionally evaluated expressions in response to incoming messages.',
);

has '+before_hook' => (
    default => 'autoreply_check',
);

has 'parser' => (
    is  => 'rw',
    isa => 'App::RoboBot::Parser',
);

has 'reply_cache' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

=head2 autoreply

=head3 Description

=head3 Usage

<name> (<condition expression>) (<response expression>)

=head3 Examples

    (autoreply "im-down" (match "qtiyd" (bot.messages/message)) (str "^"))

=cut

has '+commands' => (
    default => sub {{
        'autoreply' => { method          => 'autoreply_create',
                         preprocess_args => 0,
                         description     => 'Creates an autoreplier with the given condition and response expressions.',
                         usage           => '<name> (<condition expression>) (<response expression>)' },

        'autoreply-list' => { method      => 'autoreply_list',
                              description => 'Returns a list of the autoreplies that exist in the current channel.', },

        'autoreply-delete' => { method      => 'autoreply_delete',
                                description => 'Deletes the named autoreply for the current channel.',
                                usage       => '<name>', },

        'autoreply-show' => { method      => 'autoreply_show',
                              description => 'Displays the condition and response expressions for the named autoreply within the current channel.',
                              usage       => '<name>', },
    }},
);

sub post_init {
    my ($self, $bot) = @_;

    $self->log->info('Initializing autorepliers.');

    $self->parser( App::RoboBot::Parser->new( bot => $bot ) );

    my $res = $bot->config->db->do(q{
        select *
        from autoreply_autoreplies
    });

    while ($res->next) {
        $self->log->debug(sprintf('Caching %s autoreply data for channel ID %s.', $res->{'name'}, $res->{'channel_id'}));

        try {
            $self->reply_cache->{$res->{'channel_id'}}{$res->{'name'}} = {
                condition   => $self->parser->parse($res->{'condition'}),
                response    => $self->parser->parse($res->{'response'}),
            };
        } catch {
            $self->log->error(sprintf("Could not initialize autoreply %s: %s", $res->{'name'}, $_));
        }
    }
}

sub autoreply_check {
    my ($self, $message) = @_;

    return if $message->has_expression;

    return unless $message->has_channel;
    return unless exists $self->reply_cache->{$message->channel->id};

    $self->log->debug(sprintf('Checking autoreplies against message in %s on network %s.',
        $message->channel->name, $message->network->name));

    my $raw_text = $message->raw;

    my $check_message = App::RoboBot::Message->new(
        bot     => $self->bot,
        raw     => $raw_text,
        network => $message->channel->network,
        sender  => $message->sender,
        channel => $message->channel,
    );

    foreach my $name (sort keys %{$self->reply_cache->{$message->channel->id}}) {
        $self->log->debug(sprintf('Checking autoreply %s.', $name));

        my $reply = $self->reply_cache->{$message->channel->id}{$name};

        $check_message->raw($raw_text);
        $check_message->expression($reply->{'condition'});

        my $ret = $reply->{'condition'}->evaluate($check_message, {});

        if ($ret) {
            $self->log->debug(sprintf('Autoreply %s matched. Evaluating reply function.', $name));

            $message->response->push(
                $reply->{'response'}->evaluate($check_message, {})
            );
        }
    }
}

sub autoreply_create {
    my ($self, $message, $command, $rpl, $name, $condition, $response) = @_;

    unless (defined $name && defined $condition && defined $response) {
        $message->response->raise('Must provide an autoreplier name, condition expression, and response expression.');
        return;
    }

    if (blessed($name) && $name->can('evaluate')) {
        $name = $name->evaluate($message, $rpl);

        if (ref($name)) {
            $message->response->raise('Autoreplier name expression must evaluate to a string.');
            return;
        }
    } else {
        $name = "$name";
    }

    if (ref($name) || $name !~ m{\w+}) {
        $message->response->raise('Must provide an autoreplier name.');
        return;
    }

    unless (blessed($condition) && $condition->can('evaluate')) {
        $message->response->raise('Must provide an expression for the autoreply condition.');
        return;
    }

    unless (blessed($response) && $response->can('evaluate')) {
        $message->response->raise('Must provide an expression for the autoreply response.');
        return;
    }

    $condition->quoted(0);
    $response->quoted(0);

    $self->log->debug(sprintf('Attempting to update autoreplier with name %s in %s on network %s.',
        $name, $message->channel->name, $message->network->name));

    my $res = $self->bot->config->db->do(q{
        update autoreply_autoreplies set ??? where channel_id = ? and name = ? returning *
    }, {
        condition  => $condition->flatten,
        response   => $response->flatten,
        created_by => $message->sender->id,
        created_at => 'now',
    }, $message->channel->id, $name);

    if ($res && $res->next) {
        $self->log->debug('Autoreplier update successful.');

        $message->response->push(sprintf('Autoreply %s has been updated.', $name));
    } else {
        $self->log->debug(sprintf('No existing autoreplier to update. Creating new record.'));

        $res = $self->bot->config->db->do(q{
            insert into autoreply_autoreplies ??? returning *
        }, {
            channel_id  => $message->channel->id,
            name        => lc($name),
            condition   => $condition->flatten,
            response    => $response->flatten,
            created_by  => $message->sender->id,
        });

        if ($res && $res->next) {
            $message->response->push(sprintf('Autoreply %s has been added.', $name));
        } else {
            $self->log->error(sprintf('Could not create autoreplier record: %s', $res->error));

            $message->response->raise('Could not create the autoresponse. Please check your arguments and try again.');
            return;
        }
    }

    $self->log->debug(sprintf('Caching new/updated autoreplier %s.', $name));

    $self->reply_cache->{$message->channel->id}{lc($name)} = {
        condition   => $condition,
        response    => $response,
    };

    return;
}

sub autoreply_list {
    my ($self, $message, $command, $rpl) = @_;

    unless ($message->has_channel) {
        $message->response->raise('Autoreplies may only be used in channels.');
        return;
    }

    my $res = $self->bot->config->db->do(q{
        select name from autoreply_autoreplies where channel_id = ? order by name asc
    }, $message->channel->id);

    my @replies;

    if ($res) {
        while ($res->next) {
            push(@replies, $res->[0]);
        }
    }

    if (@replies > 0) {
        return @replies;
    } else {
        $message->response->raise('There are no autoreplies configured for this channel. Use (autoreply) to create one.');
        return;
    }
}

sub autoreply_delete {
    my ($self, $message, $command, $rpl, $name) = @_;

    unless (defined $name && $name =~ m{\w+}) {
        $message->response->raise('Must provide the name of an autoreply to display.');
        return;
    }

    unless ($message->has_channel) {
        $message->response->raise('Autoreplies may only be used in channels.');
        return;
    }

    my $res = $self->bot->config->db->do(q{
        delete from autoreply_autoreplies where channel_id = ? and lower(name) = lower(?) returning *
    }, $message->channel->id, $name);

    if ($res && $res->next) {
        $message->response->push(sprintf('The autoreply %s has been deleted from this channel.', $name));
    } else {
        $message->response->raise('There was no autoreply named %s configured for this channel for me to delete.', $name);
    }

    delete $self->reply_cache->{$message->channel->id}{lc($name)};

    return;
}

sub autoreply_show {
    my ($self, $message, $command, $rpl, $name) = @_;

    unless (defined $name && $name =~ m{\w+}) {
        $message->response->raise('Must provide the name of an autoreply to display.');
        return;
    }

    unless ($message->has_channel) {
        $message->response->raise('Autoreplies may only be used in channels.');
        return;
    }

    my $res = $self->bot->config->db->do(q{
        select * from autoreply_autoreplies where channel_id = ? and lower(name) = lower(?)
    }, $message->channel->id, $name);

    unless ($res && $res->next) {
        $message->response->raise('There is no autoreply in this channel called %s. Please check the name and try again.', $name);
        return;
    }

    $message->response->push(sprintf('Autoreply: *%s*', $res->{'name'}));
    $message->response->push(sprintf('Condition: %s', $res->{'condition'}));
    $message->response->push(sprintf('Response: %s', $res->{'response'}));

    return;
}

__PACKAGE__->meta->make_immutable;

1;
