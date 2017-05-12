package App::RoboBot::Plugin::Bot::Alarm;
$App::RoboBot::Plugin::Bot::Alarm::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use AnyEvent;
use Data::Dumper;
use JSON;
use Scalar::Util qw( blessed );

use App::RoboBot::Channel;
use App::RoboBot::Message;
use App::RoboBot::Parser;
use App::RoboBot::Response;

extends 'App::RoboBot::Plugin';

=head1 bot.alarm

Exports functions for setting and modifying alarms, which can trigger messages
at specified times or intervals.

In addition to the exported functions, this module maintains a collection of
persistent AnyEvent timer objects which are used to fire the alarm messages
asynchronously from any regular message processing.

=cut

has '+name' => (
    default => 'Bot::Alarm',
);

has '+description' => (
    default => 'Exports functions for setting and modifying alarms, which can trigger messages at specified times or intervals.',
);

=head2 set-alarm

=head3 Description

Creates a new alarm in the current channel. The only required parameters are an
alarm name and its first occurrence. An optional message may be included, which
will be echoed whenever the alarm fires. Its length and formatting are limited
only by the features of the network on which the alarm was set (e.g. IRC will
generally be a couple hundred characters or less of plain text, whereas Slack
would allow several KB of text with formatting).

Alternately, the message may be given as a quoted expression, which will be
stored and evaluated anew with each occurrence of the alarm. These expressions
will not receive any arguments, but they may interact with global variables
defined within the same network on which the alarm is created. Because the
alarms trigger in an anonymous context (i.e. they are not responses to an
individual user's message), functions which assume a user will either fail or
behave oddly.

Unquoted expressions will be evaluated once at the time of alarm creation, and
that result will simply be echoed each time the alarm triggers. You must quote
the expression if you wish it to be evaluated on each alarm occurrence.

The initial date and time of the alarm, specified with ``:first`` must be a
valid ISO8601 formatted timestamp. The timezone is optional and will default to
that of the server on which the bot is running if omitted. It must also be a
date and time in the future.

Alarms may be set to recur by specifying an interval with ``:recurring``. The
format of the interval (shockingly!) matches that of the interval type in
PostgreSQL. Before the alarm is created, a test is performed to ensure that the
alarm will not fire too often, as a small measure to prevent abuse. The alarm
creation will be rejected if it will emit messages more than a few times an
hour.

An exclusion pattern may also be specified with ``:exclude``. Any timestamps
from the recurrence interval that match the exclusion patterns will be skipped.
The format of the is a comma-separated list of ``<field>=<regular expression>``
and may use any of the PostgreSQL ``to_char(...)`` formatting fields.

=head3 Usage

<alarm name> :first <ISO8601> [:recurring <interval>] [:exclude <pattern>] [<message or quoted expression>]

=head3 Examples

    (set-alarm daily-standup
      :first     "2016-04-25 10:00:00 US/Eastern"
      :recurring "1 day"
      :exclude   "Day=(Saturday|Sunday)"
      "Daily Standup time! Meet in the large conference room.")

    (set-alarm open-tickets
      :first "2016-10-01 10:00:00 US/Eastern"
      :recurring "1 day"
      '(join "\n"
        (jq "$.[*].ticket-summary"
          (http-get (str "https://example.com/api/tickets?"
                         (query-string { :status "open" :format "json" }))))))

=head2 delete-alarm

=head3 Description

Permanently removes the named alarm from the current channel. The alarm must be
recreated from scratch if you wish to use it again.

=head3 Usage

<alarm name>

=head3 Examples

    (delete-alarm daily-standup)

=head2 show-alarm

=head3 Description

Displays the named alarm and its current settings.

=head3 Usage

<alarm name>

=head3 Examples

    (show-alarm daily-standup)

=head2 list-alarms

=head3 Description

Displays all of the alarms for the current channel, as well as their current
state (active or suspended) and their next triggering time. If the alarms are
recurring that is noted with the recurrence interval.

=head2 suspend-alarm

=head3 Description

Temporarily suspends the named alarm.

=head3 Usage

<alarm name>

=head3 Examples

    (suspend-alarm daily-standup)

=head2 resume-alarm

=head3 Description

Resumes a suspended alarm. Does nothing to alarms which are not currently
suspended. A non-recurring alarm which had been suspended during the time at
which it should have triggered is effectively deleted by resuming it. Recurring
alarms will simply skip past any triggering intervals which passed during their
suspension.

=head3 Usage

<alarm name>

=head3 Examples

    (resume-alarm daily-standup)

=cut

has '+commands' => (
    default => sub {{
        'set-alarm' => { method      => 'set_alarm',
                         preprocess_args => 0,
                         keyed_args  => 1,
                         description => 'Creates a new alarm to emit the given message in the current channel, according to the :first and :recurring options. If an alarm by the same name already exists, its settings are replaced. Alarms that have no :recurring option will be deleted after they occur.',
                         usage       => '<alarm name> :first "<ISO8601 datetime>" [:recurring "<interval specification>"] [:exclude "<date pattern exclusions>"] [<message>]',
                         example     => '"Morning Dev Standup" :first "2015-07-06 10:30 EDT" :recurring "1 day" :exclude "Day=(Saturday|Sunday)" "Meet in the large conference room."', },

        'delete-alarm' => { method      => 'delete_alarm',
                            description => 'Deletes the named alarm permanently.',
                            usage       => '<alarm name>', },

        'show-alarm' => { method      => 'show_alarm',
                          description => 'Shows an alarm and its current settings.',
                          usage       => '<alarm name>', },

        'list-alarms' => { method      => 'list_alarms',
                           description => 'Lists all of the alarms that have been set for the current channel.', },

        'resume-alarm' => { method      => 'resume_alarm',
                            description => 'Resumes repeating occurrences of a suspended alarm.',
                            usage       => '<alarm name>', },

        'suspend-alarm' => { method      => 'suspend_alarm',
                             description => 'Temporarily disables an alarm from emitting messages.',
                             usage       => '<alarm name>', },
    }},
);

has 'alarms' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

sub init {
    my ($self) = @_;

    my $res = $self->bot->config->db->do(q{
        select id
        from alarms_alarms
        where not is_suspended
    });

    return unless $res;

    while ($res->next) {
        my $alarm = $self->_get_alarm($self->bot, $res->{'id'});
        next unless defined $alarm;

        $self->_add_timer($alarm);
    }
}

sub set_alarm {
    my ($self, $message, $command, $rpl, $keyed, $name, @args) = @_;

    return unless $message->has_channel;

    $name = $name->evaluate($message, $rpl) if defined $name && blessed($name) && $name->can('evaluate');

    unless (defined $name && $name =~ m{\w+}) {
        $message->response->raise('Every alarm must have a name. Please try again.');
        return;
    }

    unless (exists $keyed->{'first'}) {
        $message->response->raise('You must provide the first occurrence of the alarm, using the :first option, in ISO8601 format.');
        return;
    }

    my $res = $self->bot->config->db->do(q{ select 1 where ?::timestamptz > now() }, $keyed->{'first'});

    unless ($res && $res->next) {
        $message->response->raise('The value of :first must be a valid ISO8601 timestamp in the future.');
        return;
    }

    my %alarm = (
        channel_id    => $message->channel->id,
        created_by    => $message->sender->id,
        name          => $name,
        next_emit     => $keyed->{'first'},
        is_suspended  => 'f',
        is_expression => 'f',
    );

    if (@args == 1 && blessed($args[0]) && $args[0]->type eq 'Expression') {
        if ($args[0]->quoted) {
            $alarm{'is_expression'} = 't';
            $alarm{'message'} = $args[0]->flatten;
        } else {
            $alarm{'message'} = join(' ', $args[0]->evaluate($message, $rpl));
        }
    } elsif (@args > 0) {
        $alarm{'message'} = join(' ', map { $_->evaluate($message, $rpl) } @args);
    }

    if (exists $keyed->{'recurring'}) {
        $res = $self->bot->config->db->do(q{ select ?::interval }, $keyed->{'recurring'});

        unless ($res && $res->next) {
            $message->response->raise('The value of :recurring must be a valid PostgreSQL interval.');
            return;
        }

        # For now, just hardcode a limit that no alarm may emit more than five
        # times in a given hour. To do this, assume a :first of now, and use
        # generate series with the providing :recurring.
        $res = $self->bot->config->db->do(q{
            select count(*)
            from ( select generate_series(now(), now() + interval '1 hour', ?::interval) ) d
        }, $keyed->{'recurring'});

        unless ($res && $res->next) {
            $message->response->raise('An error was encountered validating alarm frequency limits.');
            return;
        }

        if ($res->[0] > 5) {
            $message->response->raise('The :recurring interval you provided would cause this alarm to trigger too frequently. Please choose a longer interval.');
            return;
        }

        $alarm{'recurrence'} = $keyed->{'recurring'};
    }

    if (exists $keyed->{'exclude'}) {
        $alarm{'exclusions'} = [];
        my @rules = split(',', $keyed->{'exclude'});

        foreach my $rule (@rules) {
            my ($format, $pattern) = split('=', $rule);

            # Test the individual format and pattern. Though to_char() will take
            # just about anything for a format string, invalid regexes will at
            # least be caught here before saving a bad alarm.
            $res = $self->bot->config->db->do(q{
                select to_char(now(), ?) ~* ?
            }, $format, $pattern);

            unless ($res && $res->next) {
                $message->response->raise('Invalid exclusion encountered (%s=%s). Please ensure that :exclude is formatted properly (e.g. "fmt1=pattern1,fmt2=pattern2,...").');
                return;
            }

            push(@{$alarm{'exclusions'}}, { format => $format, pattern => $pattern });
        }
    }

    $alarm{'exclusions'} = encode_json($alarm{'exclusions'} // []);

    $res = $self->bot->config->db->do(q{
        update alarms_alarms
        set ???
        where channel_id = ? and lower(name) = lower(?)
        returning id
    }, \%alarm, $message->channel->id, $name);

    if ($res && $res->next) {
        $alarm{'id'} = $res->{'id'};
    } else {
        # Enforce a limit on the number of alarms one user may create.
        # TODO: Make this a configuration option, and allow exemptions for
        #       specific users (or perhaps different limit tiers).
        $res = $self->bot->config->db->do(q{
            select count(*) from alarms_alarms where created_by = ?
        }, $message->sender->id);

        if ($res && $res->next && $res->[0] >= 10) {
            $message->response->raise('You have already created the maximum number of alarms. Delete some, or allow non-recurring ones to expire first.');
            return;
        }

        $res = $self->bot->config->db->do(q{
            insert into alarms_alarms ??? returning id
        }, \%alarm);

        if ($res && $res->next) {
            $alarm{'id'} = $res->{'id'};
        } else {
            $message->response->raise('Could not save your alarm. Please try again.');
            return;
        }
    }

    $self->_add_timer(\%alarm);

    # TODO: Notify channel of alarm creation and next emittance.
    $message->response->push(sprintf('The alarm "%s" has been added to this channel.', $name));
    return;
}

sub delete_alarm {
    my ($self, $message, $command, $rpl, $name) = @_;

    return unless $message->has_channel;

    my $res = $self->bot->config->db->do(q{
        select id
        from alarms_alarms
        where channel_id = ? and lower(name) = lower(?)
    }, $message->channel->id, $name);

    if ($res && $res->next) {
        $self->bot->config->db->do(q{
            delete from alarms_alarms where id = ?
        }, $res->{'id'});

        $message->response->push(sprintf('The alarm "%s" has been permanently deleted.', $name));
    } else {
        $message->response->raise('There is no alarm named "%s" in this channel.', $name);
    }

    return;
}

sub show_alarm {
    my ($self, $message, $command, $rpl, $name) = @_;

    return unless $message->has_channel;

    my $res = $self->bot->config->db->do(q{
        select id
        from alarms_alarms
        where channel_id = ? and lower(name) = lower(?)
    }, $message->channel->id, $name);

    unless ($res && $res->next) {
        $message->response->raise('There is no alarm named "%s" in this channel.', $name);
        return;
    }

    my $alarm = $self->_get_alarm($self->bot, $res->{'id'});

    unless (defined $alarm) {
        $message->response->raise('There was an error retrieving the alarm "%s". Please try again.', $name);
        return;
    }

    $message->response->push(
        sprintf('Alarm *%s* is next scheduled to trigger at %s.', $alarm->{'name'}, $alarm->{'next_emit'}),
    );

    if ($alarm->{'recurrence'}) {
        $message->response->push(sprintf('This alarm recurs every _%s_.', $alarm->{'recurrence'}));
    } else {
        $message->response->push('This alarm will not recur, and will be deleted automatically at the above time.');
    }

    if (@{$alarm->{'exclusions'}} > 0) {
        $message->response->push(sprintf('The alarm is skipped under the following conditions: %s',
            join(' or ', map { sprintf('%s ~* %s', $_->{'format'}, $_->{'pattern'}) } @{$alarm->{'exclusions'}})
        ));
    }

    $message->response->push('This alarm is currently *suspended.*') if $alarm->{'is_suspended'};

    return;
}

sub list_alarms {
    my ($self, $message, $command, $rpl) = @_;

    return unless $message->has_channel;

    my $res = $self->bot->config->db->do(q{
        select a.name, a.is_suspended
        from alarms_alarms a
        where a.channel_id = ?
        order by lower(a.name) asc
    }, $message->channel->id);

    if ($res && $res->count > 0) {
        $message->response->push('The following alarms have been set for this channel:');

        while ($res->next) {
            $message->response->push(sprintf('%s%s', $res->{'name'}, ($res->{'is_suspended'} ? ' (Suspended)' : '')));
        }
    } else {
        $message->response->push('No alarms have been set for this channel. Use (set-alarm) to create one.');
    }

    return;
}

sub resume_alarm {
    my ($self, $message, $command, $rpl, $name) = @_;

    return unless $message->has_channel;

    my $res = $self->bot->config->db->do(q{
        select id, is_suspended
        from alarms_alarms
        where channel_id = ? and lower(name) = lower(?)
    }, $message->channel->id, $name);

    unless ($res && $res->next) {
        $message->response->raise('There is no alarm named "%s" in this channel.', $name);
        return;
    }

    unless ($res->{'is_suspended'}) {
        $message->response->raise('The alarm "%s" is not currently suspended.', $name);
        return;
    }

    # Update suspended bool in database.
    $self->bot->config->db->do(q{
        update alarms_alarms set is_suspended = false where id = ?
    }, $res->{'id'});

    # Delegate to _get_alarm so that it can handle calculations for next_emit.
    my $alarm = $self->_get_alarm($self->bot, $res->{'id'});

    return unless defined $alarm;

    $self->_add_timer($alarm);

    $message->response->push(sprintf('The alarm "%s" has been resumed.', $name));
    return;
}

sub suspend_alarm {
    my ($self, $message, $command, $rpl, $name) = @_;

    return unless $message->has_channel && defined $name;

    my $res = $self->bot->config->db->do(q{
        select id, is_suspended
        from alarms_alarms
        where channel_id = ?
            and lower(name) = lower(?)
    }, $message->channel->id, $name);

    unless ($res && $res->next) {
        $message->response->raise('There is no alarm named "%s" in this channel.', $name);
        return;
    }

    if ($res->{'is_suspended'}) {
        $message->response->raise('The alarm "%s" is already suspended.', $name);
        return;
    }

    # Remove from the active alarm timers.
    delete $self->alarms->{$res->{'id'}};

    # Update in the database.
    $self->bot->config->db->do(q{
        update alarms_alarms set is_suspended = true where id = ?
    }, $res->{'id'});

    $message->response->push(sprintf('The alarm "%s" has been suspended.', $name));
    return;
}

sub _get_alarm {
    my ($self, $bot, $alarm_id) = @_;

    # We buffer the comparison of the current next_emit to now() by a little bit
    # into the future to account for the possibility of timer drift, and any
    # other delays that may occur between when the timer is schedule to fire and
    # when our bot's single execution thread finally reaches this point. One
    # minute is a major buffer, but alarms cannot be scheduled to trigger more
    # than a few times each hour anyway.
    my $res = $bot->config->db->do(q{
        select a.*,
            case
                when a.next_emit <= (now() + interval '1 minute') then 1
                else 0
            end as do_recalc
        from alarms_alarms a
        where a.id = ?
    }, $alarm_id);

    return unless $res && $res->next;

    $res->{'exclusions'} = decode_json($res->{'exclusions'});

    if ($res->{'do_recalc'} && $res->{'recurrence'}) {
        # Alarm's recorded next occurrence has expired, so we need to recalc
        # and updated the database before we send the alarm back to the caller.

        # Pad the clause so a lack of exclusions doesn't generate bad SQL.
        my @where = qw( false );
        my @binds;

        foreach my $excl (@{$res->{'exclusions'}}) {
            push(@where, 'to_char(s.new_emit, ?) ~* ?');
            push(@binds, $excl->{'format'}, $excl->{'pattern'});
        }

        # TODO: Alarms which have been suspended for a long time (where "long"
        #       is defined by the scale of their recurrence rate), will not get
        #       a new_emit properly from this query. I.e. a daily alarm that
        #       has been suspended for more than 100 days will get an empty
        #       resultset. Fix this in a way that is better than simply using
        #       larger and larger multiples on the interval for the stop in
        #       generate_series().
        my $new_emit = $self->bot->config->db->do(q{
            select date_trunc('seconds', s.new_emit) as new_emit
            from alarms_alarms a,
                generate_series(a.next_emit, a.next_emit + (a.recurrence * 100), a.recurrence) s(new_emit)
            where a.id = ? and a.recurrence is not null and not (} . join(' or ', @where) . q{)
                and s.new_emit > (now() + (a.recurrence / 2))
            order by s.new_emit asc
            limit 1
        }, $res->{'id'}, @binds);

        if ($new_emit && $new_emit->next) {
            # We have a properly calculated next_emit, so update the alarm in
            # the database with a returning * clause so we can get the alarm
            # back to our caller.
            $res = $self->bot->config->db->do(q{
                update alarms_alarms set next_emit = ? where id = ? returning *
            }, $new_emit->{'new_emit'}, $res->{'id'});

            unless ($res && $res->next) {
                return;
            }
        } else {
            # Something has gone wrong, but we can't really send a message out.
            # Suspend the alarm to prevent further problems.
            $self->bot->config->db->do(q{
                update alarms_alarms set is_suspended = true where id = ?
            }, $res->{'id'});

            return;
        }
    } elsif ($res->{'do_recalc'}) {
        # The current value of next_emit is in the past, but we have a NULL
        # recurrence, which means this alarm should be deleted so it doesn't
        # ever fire again.
        $self->bot->config->db->do(q{
            delete from alarms_alarms where id = ?
        }, $res->{'id'});
    }

    my %alarm = ( map { $_ => $res->{$_} } $res->columns );
    return \%alarm;
}

sub _emit_alarm {
    my ($self, $alarm_id) = @_;

    return unless defined $alarm_id && $alarm_id =~ m{^\d+$};

    my $alarm = $self->_get_alarm($self->bot, $alarm_id);
    return unless defined $alarm;

    my $channel = App::RoboBot::Channel->find_by_id($self->bot, $alarm->{'channel_id'});
    return unless defined $channel;

    my $response = App::RoboBot::Response->new(
        network => $channel->network,
        channel => $channel,
        bot     => $self->bot,
    );

    my $message;
    if ($alarm->{'is_expression'}) {
        my $parser = App::RoboBot::Parser->new( bot => $self->bot );
        # Parse the alarm's expression after dropping the leading expression quote
        my $expr = $parser->parse(substr($alarm->{'message'}, 1));

        if (defined $expr && blessed($expr) && $expr->can('evaluate')) {
            # Need a dummy App::RoboBot::Message for expression evaluation.
            my $msg = App::RoboBot::Message->new(
                bot      => $self->bot,
                raw      => "",
                network  => $channel->network,
                sender   => $channel->network->nick, # Consider replacing this with the ::Nick of the person who created the alarm
                channel  => $channel,
                response => $response
            );
            $message = $expr->evaluate($msg, {});
        }
    } elsif ($alarm->{'message'}) {
        $message = $alarm->{'message'};
    }

    $response->push($message) if defined $message && $message =~ m{\w+};
    $response->send;

    if ($alarm->{'next_emit'} && $alarm->{'recurrence'}) {
        $self->_add_timer($alarm);
    }
}

sub _add_timer {
    my ($self, $alarm) = @_;

    my $res = $self->bot->config->db->do(q{
        select extract(epoch from ? - now())::int as delay
    }, $alarm->{'next_emit'});

    return unless $res && $res->next && $res->{'delay'} > 0;

    $self->alarms->{$alarm->{'id'}} = AnyEvent->timer(
        after => $res->{'delay'},
        cb    => sub { $self->_emit_alarm($alarm->{'id'}) },
    );
}

__PACKAGE__->meta->make_immutable;

1;
