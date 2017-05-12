package App::RoboBot::Plugin::Social::Achievements;
$App::RoboBot::Plugin::Social::Achievements::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

use Data::Dumper;

extends 'App::RoboBot::Plugin';

=head1 social.achievements

Exports functions for creating and viewing chat achievements, which are much
like the ridiculous fake-internet-point badges from video games.

Each achievement has a name, a description, and a SQL query which is run to
determine whether a specific user has met the requirements to earn the badge.

In addition to the xported functions, the module inserts a post-hook into the
message processing pipeline of App::RoboBot which retrieves the list of achievements
not yet earned by the user whose message was just processed, executes each
achievement's associated SQL query, and if the query returns a true value in
the first column of the first row the hook then awards the achievement to the
user and notifies them with a congratulatory message. For this reason, the
queries used to determine achievement eligibility must execute quickly.

=cut

has '+name' => (
    default => 'Social::Achievements',
);

has '+description' => (
    default => 'Exports functions for creating and viewing chat achievements.',
);

has '+after_hook' => (
    default => 'check_achievements',
);

=head2 add-achievement

=head3 Description

Creates a new achievement. Achievements must have a name, a description, and a
SQL query which is used to determine a person's eligibility. The query must
return a true value in the first column of the first row to indicate that the
user may earn the achievement. Anything else will consider the user ineligible
at that time.

Achievements are currently earned only a single time. There is no support for
recurring achievements (tiers/levels which increment).

Because the SQL query is executed every time a message is processed from a user
who has not yet earned the achievement, they must be written for speed. The SQL
query will receive a single bind variable: the ``nick_id`` of the user whose
message was just processed.

=head3 Usage

<name> <description> <query>

=head3 Examples

    (add-achievement
      Chatterbox
      "You love the sound of your own keyboard. You've sent 10,000 messages!"
      "select count(*) >= 10000 from logger_log where nick_id = ?")

=head2 show-achievement

=head3 Description

Displays the details of the named achievement, along with a list of the people
who have earned it and when they did so.

=head3 Usage

<achievement name>

=head3 Examples

    (show-achievement Chatterbox)

=head2 list-achievements

=head3 Description

Displays all achievements available, along with the number of people on the
current network who have earned each one.

=head2 achievements

=head3 Description

Displays the achievements earned by the named user (or the current user if no
name is supplied). The date on which the achievement was earned is displayed
next to each one.

=head3 Usage

[<nick>]

=head3 Examples

    (achievements)
    (achievements Beauford)

=cut

has '+commands' => (
    default => sub {{
        'add-achievement' => { method      => 'add_achievement',
                               description => 'Creates a new achievement.',
                               usage       => '<name> <description> <query>',
                               example     => '"Chatterbox" "You love the sound of your own keyboard clacking away. So much that you\'ve typed over 10,000 messages now!" "select count(*) >= 10000 from logger_log where nick_id = ?"', },

        'show-achievement' => { method      => 'show_achievement',
                                description => 'Shows the details of the named achievement, including a list of the people who have earned it so far.',
                                usage       => '<achievement name>', },

        'list-achievements' => { method      => 'list_achievements',
                                 description => 'Lists all achievements.', },

        'achievements' => { method      => 'nick_achievements',
                            description => 'Lists the achievements earned by the provided nick (or your own achievements if no nick is provided.)',
                            usage       => '[<nick>]', },
    }},
);

sub list_achievements {
    my ($self, $message, $command, $rpl) = @_;

    my $res = $self->bot->config->db->do(q{
        select name
        from achievements
        order by name asc
    });

    if ($res) {
        my @l;
        while ($res->next) {
            push(@l, $res->{'name'});
        }

        if (@l > 0) {
            $message->response->push(sprintf('The following achievements are available: %s', join(', ', @l)));
        } else {
            $message->response->push('There are no achievements.');
        }
    }

    return;
}

sub show_achievement {
    my ($self, $message, $command, $rpl, @args) = @_;

    return unless @args;
    my $name = join(' ', @args);

    my $res = $self->bot->config->db->do(q{
        select a.id, a.name, a.description
        from achievements a
        where lower(name) = lower(?)
    }, $name);

    unless ($res && $res->next) {
        $message->response->raise('No matching achievement found.');
        return;
    }

    $message->response->push(sprintf('Achievement: %s', $res->{'name'}));
    $message->response->push($res->{'description'});

    $res = $self->bot->config->db->do(q{
        select n.name
        from nicks n
            join logger_log l on (l.nick_id = n.id)
            join channels c on (c.id = l.channel_id)
            join achievement_nicks an on (an.nick_id = n.id)
        where an.achievement_id = ?
            and c.network_id = ?
        group by n.name
        order by n.name asc
    }, $res->{'id'}, $message->network->id);

    my @names;
    while ($res->next) {
        push(@names, $res->{'name'});
    }

    my $num_names = scalar @names;
    $message->response->push(sprintf('Earned %d time%s.', $num_names, $num_names == 1 ? '' : 's'));

    # Cut out here for now, instead of printing recipient names. Listing everyone
    # probably leads to annoying pings, especially if someone decides to start
    # checking out the details of a bunch of different achievements.
    return;

    if ($num_names > 0) {
        $message->response->push(sprintf('Recipients: %s', join(', ', @names)));
    }

    return;
}

sub nick_achievements {
    my ($self, $message, $command, $rpl, $nick) = @_;

    $nick //= $message->sender->name;

    my $res = $self->bot->config->db->do(q{
        select a.name, an.created_at::date as earned
        from achievements a
            join achievement_nicks an on (an.achievement_id = a.id)
            join nicks n on (n.id = an.nick_id)
        where lower(n.name) = lower(?)
        order by an.created_at asc, a.name asc
    }, $nick);

    return unless $res;

    my @achievements;

    while ($res->next) {
        push(@achievements, sprintf('%s (%s)', $res->{'name'}, $res->{'earned'}));
    }

    if (@achievements > 0) {
        $message->response->push(join(', ', @achievements));
    } else {
        $message->response->push(sprintf('No achievements have been earned by %s yet.', $nick));
    }

    return;
}

sub add_achievement {
    my ($self, $message, $command, $rpl, $name, $desc, $query) = @_;

    $message->response->push('Achievements must be added manually, to prevent abuse. Contact your neighborhood App::RoboBot representative for details.');
    return;
}

sub check_achievements {
    my ($self, $message) = @_;

    my $res = $self->bot->config->db->do(q{
        select a.*
        from achievements a
            left join achievement_nicks an on (an.achievement_id = a.id and an.nick_id = ?)
            left join nicks n on (n.id = an.nick_id)
        where n.id is null
        order by a.name asc
    }, $message->sender->id);

    return unless $res;

    while ($res->next) {
        my $check = $self->bot->config->db->do($res->{'query'}, $message->sender->id);
        next unless $check && $check->next;

        if ($check->[0] == 1) {
            $self->bot->config->db->do(q{
                insert into achievement_nicks ???
            }, {
                achievement_id => $res->{'id'},
                nick_id        => $message->sender->id,
            });

            $message->response->push(sprintf('Congratulations, %s! You just earned the _%s_ achievement. %s',
                $message->sender->name, $res->{'name'}, $res->{'description'}));
        }
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;
