package App::RoboBot::Plugin::Social::Karma;
$App::RoboBot::Plugin::Social::Karma::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use App::RoboBot::Nick;

use Number::Format;

extends 'App::RoboBot::Plugin';

=head1 social.karma

Modifies and displays karma/reputation points.

In addition to the exported functions, this module inserts a pre-hook into the
message processing pipeline which looks for any karma giving/taking. Any
substrings in messages which match ``nick++`` or ``nick--`` are extracted and
used to automatically increment or decrement, respectively, the named person's
global karma.

A user's karma is calculated using a weighted formula that discourages a single
benefactor or detractor from completely dominating their target's reputation.
It is not a simple integer. Though this module would be much less obtuse if it
were, because karma currently calculates pretty weirdly in some circumstances.
The end goal is for the number of distinct benefactors/detractors to matter
more than the number of grants/revokes performed by a single entity. Stated
another way, "more distinct people liking me is more powerful than one person
really hating me."

=cut

has '+name' => (
    default => 'Social::Karma',
);

has '+description' => (
    default => 'Modifies and displays karma/reputation points.',
);

has '+before_hook' => (
    default => 'update_karma',
);

=head2 karma

=head3 Description

Displays the named person's current karma. Multiple nicks may be provided and
they will all have their karma displayed.

=head3 Usage

[<nick> [<nick> ...]]

=head3 Examples

=head2 ++karma

=head3 Description

The explicit function call version of incrementing the named person's karma.

=head3 Usage

<nick>

=head3 Examples

=head2 --karma

=head3 Description

The explicit function call version of decrementing the named person's karma.

=head3 Usage

<nick>

=head3 Examples

=head2 karma-leaders

=head3 Description

Displays the highest reputation users on the current network. Any ties are
sorted alphabetically.

=head2 karma-losers

=head3 Description

Displays the lowest reputation users on the current network. Any ties are
sorted alphabetically.

=cut

has '+commands' => (
    default => sub {{
        'karma' => { method      => 'display_karma',
                     description => 'Displays current karma/reputation points for given nicks. Defaults to displaying karma of caller.',
                     usage       => '[<nick> ... <nick N>]' },

        '++karma' => { method      => 'add_karma',
                       description => "Explicitly adds to the given nick's karma rating.",
                       usage       => '<nick>' },

        '--karma' => { method      => 'subtract_karma',
                       description => "Explicitly subtracts from the given nick's karma rating.",
                       usage       => '<nick>' },

        'karma-leaders' => { method      => 'karma_leaders',
                             description => 'Displays the nicks on your current network with the highest current karma.', },

        'karma-losers' => { method      => 'karma_losers',
                            description => 'Displays the nicks on your current network with the lowest current karma.', },
    }},
);

has 'nf' => (
    is      => 'ro',
    isa     => 'Number::Format',
    default => sub { Number::Format->new() }
);

sub add_karma {
    my ($self, $message, $command, $rpl, $nick) = @_;

    $nick = App::RoboBot::Nick->new( config => $self->bot->config, name => "$nick" );

    # Users can self-karma--, but they can't add karma to their own nick.
    if (defined $nick && $nick->id != $message->sender->id) {
        my $res = $self->bot->config->db->do(q{
            insert into karma_karma ???
        }, {
            nick_id      => $nick->id,
            karma        => 1,
            from_nick_id => $message->sender->id,
        });
    }

    return;
}

sub subtract_karma {
    my ($self, $message, $command, $rpl, $nick) = @_;

    $nick = App::RoboBot::Nick->new( config => $self->bot->config, name => "$nick" );

    if (defined $nick) {
        my $res = $self->bot->config->db->do(q{
            insert into karma_karma ???
        }, {
            nick_id      => $nick->id,
            karma        => -1,
            from_nick_id => $message->sender->id,
        });
    }

    return;
}

sub update_karma {
    my ($self, $message) = @_;

    my %nicks = ($message->raw =~ m{([A-Za-z0-9_]+)([+-]{2})}ogs);

    return unless scalar(keys %nicks) > 0;

    foreach my $nick (keys %nicks) {
        my $karma_amount = $nicks{$nick} eq '++' ? 1 : -1;

        my $res = $self->bot->config->db->do(q{
            select id
            from nicks
            where lower(name) = lower(?)
        }, $nick);

        if ($res && $res->next) {
            next if $karma_amount > 0 && $res->{'id'} == $message->sender->id;

            my $nick_id = $res->{'id'};

            $self->bot->config->db->do(q{
                insert into karma_karma ???
            }, {
                nick_id      => $nick_id,
                karma        => $karma_amount,
                from_nick_id => $message->sender->id,
            });
        }
    }
}

sub display_karma {
    my ($self, $message, $command, $rpl, @nicks) = @_;

    if (!@nicks || @nicks < 1) {
        @nicks = ($message->sender->name);
    }

    foreach my $nick (@nicks) {
        my $res = $self->bot->config->db->do(q{
            select id, name
            from nicks
            where lower(name) = lower(?)
        }, $nick);

        next unless $res && $res->next;

        my $nick_id = $res->{'id'};
        my $nick_name = $res->{'name'};

        $res = $self->bot->config->db->do(q{
            with t as (select count(*) as nicks from nicks)
            select n.name,
                coalesce(sum(k.karma)::real * (count(distinct(k.from_nick_id))::real / t.nicks), 0) * 100 as karma
            from karma_karma k
                join nicks n on (n.id = k.nick_id),
                t
            where n.id = ?
            group by n.name, t.nicks
        }, $nick_id);

        my $karma = 0;
        if ($res && $res->next) {
            $karma = $res->{'karma'};
        }

        $message->response->push(sprintf('%s currently has %s karma.', $nick_name, $self->nf->format_number($karma || 0, 4, 1)));
    }

    return;
}

sub karma_leaders {
    my ($self, $message, $command, $rpl) = @_;

    my $res = $self->bot->config->db->do(q{
        with t as (select count(*) as nicks from nicks)
        select n.name as nick,
            coalesce(sum(k.karma)::real * (count(distinct(k.from_nick_id))::real / t.nicks), 0) * 100 as karma
        from karma_karma k
            join nicks n on (n.id = k.nick_id),
            t
        where length(n.name) > 0
            and n.id in ( select n.id
                          from nicks n
                              join logger_log l on (l.nick_id = n.id)
                              join channels c on (c.id = l.channel_id)
                          where c.network_id = ?
                          group by n.id)
        group by t.nicks, n.name
        order by 2 desc, n.name asc
        limit 5
    }, $message->network->id);

    if ($res) {
        while ($res->next) {
            $message->response->push(sprintf('*%s*: %s', $res->nick, $self->nf->format_number($res->{'karma'} || 0, 4, 1)));
        }
    }

    return;
}

sub karma_losers {
    my ($self, $message, $command, $rpl) = @_;

    my $res = $self->bot->config->db->do(q{
        with t as (select count(*) as nicks from nicks)
        select n.name as nick,
            coalesce(sum(k.karma)::real * (count(distinct(k.from_nick_id))::real / t.nicks), 0) * 100 as karma
        from karma_karma k
            join nicks n on (n.id = k.nick_id),
            t
        where length(n.name) > 0
            and n.id in ( select n.id
                          from nicks n
                              join logger_log l on (l.nick_id = n.id)
                              join channels c on (c.id = l.channel_id)
                          where c.network_id = ?
                          group by n.id)
        group by t.nicks, n.name
        order by 2 asc, n.name asc
        limit 5
    }, $message->network->id);

    if ($res) {
        while ($res->next) {
            $message->response->push(sprintf('*%s*: %s', $res->nick, $self->nf->format_number($res->{'karma'} || 0, 4, 1)));
        }
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;
