package App::RoboBot::Plugin::Social::Voting;
$App::RoboBot::Plugin::Social::Voting::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

extends 'App::RoboBot::Plugin';

has '+name' => (
    default => 'Social::Voting',
);

has '+description' => (
    default => 'Provides functions for creating, voting on, and tallying polls.',
);

has '+commands' => (
    default => sub {{
        'propose' => { method      => 'voting_propose',
                       description => 'Creates a new poll question, with allowed responses (and optional write-in). Displays the poll ID and instructions on voting.',
                       usage       => '"<question>" <response1> ... <responseN> [:write-in]',
                       example     => '"What should we get for lunch?" Pizza Indian "Bucket of cookies" :write-in', },

        'poll' => { method      => 'voting_poll',
                    description => 'Displays the given polling question and available options (with the respective tallies if any votes have already been cast).',
                    usage       => '<poll id>', },

        'polls' => { method      => 'voting_polls',
                     description => 'Displays the current list of open questions for the current channel.', },

        'vote' => { method      => 'voting_vote',
                    description => 'Casts a vote on the given poll. If you have alredy voted, your ballot will be updated with your new choice. Votes cannot be cast on closed polls. If the poll allows write-ins, you may cast your vote for any arbitrary string instead of just the numbered options.',
                    example     => '<poll id> <choice>', },

        'tally' => { method      => 'voting_tally',
                     description => 'Closes the named poll and displays the final tally of votes. Only the user who created the poll may close it.',
                     usage       => '<poll id>', },
    }},
);

sub voting_propose {
    my ($self, $message, $command, $rpl, $question, @choices) = @_;

    unless ($message->has_channel) {
        $message->response->raise('Polls may only be created inside a channel.');
        return;
    }

    unless (@choices && (@choices > 1 || lc($choices[0]) eq 'write-in')) {
        $message->response->raise('Polls must have at least two choices (or allow write-ins).');
        return;
    }

    my $poll = {
        name        => $question,
        channel_id  => $message->channel->id,
        created_by  => $message->sender->id,
        can_writein => 'f'
    };
    $poll->{'can_writein'} = 't' if grep { lc($_) eq 'write-in' } @choices;

    my $res = $self->bot->config->db->do(q{ insert into voting_polls ??? returning poll_id }, $poll);

    unless ($res && $res->next) {
        $message->response->raise('Could not create poll. Please check your syntax and try again. Use (help propose) to see options.');
        return;
    }

    my $poll_id = $res->{'poll_id'};

    foreach my $choice (grep { lc($_) ne 'write-in' } @choices) {
        $self->bot->config->db->do(q{ insert into voting_poll_choices ??? }, { poll_id => $poll_id, name => $choice });
    }

    return $self->voting_poll($message, 'poll', $rpl, $poll_id);
}

sub voting_poll {
    my ($self, $message, $command, $rpl, $poll_id) = @_;

    unless (defined $poll_id && $poll_id =~ m{^\d+$}) {
        $message->response->raise('A poll number is required to view poll details.');
        return;
    }

    unless ($message->has_channel) {
        $message->response->raise('Polls may only be conducted inside a channel.');
        return;
    }

    my $poll = $self->bot->config->db->do(q{
        select p.poll_id, p.name, p.can_writein, p.created_at, p.closed_at,
            n.name as nick
        from voting_polls p
            join nicks n on (n.id = p.created_by)
        where poll_id = ?
            and channel_id = ?
    }, $poll_id, $message->channel->id);

    unless ($poll && $poll->next) {
        $message->response->raise('No poll by that number could be located for this channel. View this channel\'s polls with (polls).');
        return;
    }

    $message->response->push(sprintf('*%s* by %s', $poll->name, $poll->{'nick'}));

    my $choice = $self->bot->config->db->do(q{
        select c.name, c.is_writein, count(v.vote_id) as num_votes
        from voting_poll_choices c
            left join voting_votes v on (v.choice_id = c.choice_id)
        where c.poll_id = ?
        group by c.name, c.is_writein
        order by case when c.is_writein then 1 else 0 end asc, lower(c.name) asc
    }, $poll_id);

    my $high_vote = 1; # must receive at least 1 vote to be considered the winner.
    my @winners;

    while ($choice->next) {
        $message->response->push(sprintf('%s: %d%s', $choice->{'name'}, $choice->{'num_votes'}, ($choice->{'is_writein'} ? ' (write-in)' : '')));

        if ($choice->{'num_votes'} > $high_vote) {
            $high_vote = $choice->{'num_votes'};
            @winners = ($choice->{'name'});
        } elsif ($choice->{'num_votes'} == $high_vote) {
            push(@winners, $choice->{'name'});
        }
    }

    if ($poll->{'closed_at'}) {
        $message->response->push(sprintf('This poll has closed and no new votes will be accepted.'));
        if (@winners > 0) {
            $message->response->push(sprintf('The winner%s %s with %d vote%s%s.',
                (@winners > 1 ? 's were' : ' was'),
                join(', ', map { sprintf('"%s"', $_) } @winners),
                $high_vote,
                ($high_vote == 1 ? '' : 's'),
                (@winners > 1 ? ' each' : '')));
        } else {
            $message->response->push('There was no winner.');
        }
    } else {
        $message->response->push(sprintf('To vote in this poll, use: (vote %d "your choice here")', $poll->{'poll_id'}));
    }

    return;
}

sub voting_polls {
    my ($self, $message, $command, $rpl) = @_;

    unless ($message->has_channel) {
        $message->response->raise('Polls may only be conducted within channels.');
        return;
    }

    my $polls = $self->bot->config->db->do(q{
        select p.poll_id, p.name, p.created_at, count(distinct(v.vote_id)) as num_votes
        from voting_polls p
            left join voting_poll_choices c on (c.poll_id = p.poll_id)
            left join voting_votes v on (v.choice_id = c.choice_id)
        where p.channel_id = ?
            and p.closed_at is null
        group by p.poll_id, p.name, p.created_at
        order by p.created_at asc
    }, $message->channel->id);

    my $poll_count = 0;

    while ($polls->next) {
        $poll_count++;
        $message->response->push(sprintf('%d: *%s* created on %s with %d votes so far',
            $polls->{'poll_id'},
            $polls->{'name'},
            $polls->{'created_at'},
            $polls->{'num_votes'}));
    }

    if ($poll_count > 0) {
        $message->response->push('To view the details of a specific poll, including voting options, use (poll <num>)');
        $message->response->unshift(sprintf('There %s %d poll%s open for this channel:',
            ($poll_count == 1 ? 'is' : 'are'),
            $poll_count,
            ($poll_count == 1 ? '' : 's')));
    } else {
        $message->response->push('There are no open polls in this channel. Use (help propose) to see how to create one.');
    }

    return;
}

sub voting_vote {
    my ($self, $message, $command, $rpl, $poll_id, @args) = @_;

    unless ($message->has_channel) {
        $message->response->raise('Polls may only be conducted within channels.');
        return;
    }

    # Slurp up remaining args into a single string, so users aren't forced to stringquote their ballots.
    my $choice = @args ? join(' ', @args) : '';

    unless (defined $poll_id && defined $choice && $poll_id =~ m{^\d+$} && $choice =~ m{\w+}) {
        $message->response->raise('You must supply both a poll number and a voting choice. Please try again.');
        return;
    }

    $choice =~ s{(^\s+|\s+$)}{}gs;
    $choice =~ s{\s+}{ }gs;

    my $poll = $self->bot->config->db->do(q{
        select * from voting_polls where poll_id = ? and channel_id = ?
    }, $poll_id, $message->channel->id);

    unless ($poll && $poll->next) {
        $message->response->raise('That poll number is not valid. To view the open polls for this channel, use: (polls)');
        return;
    }

    if ($poll->{'closed_at'}) {
        $message->response->raise('That poll has already closed and no new votes are being accepted. To view the results, use: (poll %d)', $poll->{'poll_id'});
        return;
    }

    my $poll_choice = $self->bot->config->db->do(q{
        select * from voting_poll_choices where poll_id = ? and lower(name) = lower(?)
    }, $poll_id, $choice);

    my $choice_id;

    if ($poll_choice && $poll_choice->next) {
        $choice_id = $poll_choice->{'choice_id'};
    } elsif ($poll->{'can_writein'}) {
        $poll_choice = $self->bot->config->db->do(q{
            insert into voting_poll_choices ??? returning choice_id
        }, {
            poll_id    => $poll_id,
            name       => $choice,
            is_writein => 't',
            writein_by => $message->sender->id,
            writein_at => 'now'
        });

        if ($poll_choice && $poll_choice->next) {
            $choice_id = $poll_choice->{'choice_id'};
        } else {
            $message->response->raise('Could not create your write-in vote. Please check your ballot and try again.');
            return;
        }
    } else {
        $message->response->raise(sprintf('The choice "%s" is not valid for this poll (and it does not accept write-ins). Please use (poll %d) to view choices and try again.', $choice, $poll_id));
        return;
    }

    my $vote = $self->bot->config->db->do(q{
        update voting_votes
        set choice_id = ?,
            voted_at = now()
        where vote_id = ( select v.vote_id
                          from voting_votes v
                            join voting_poll_choices c on (c.choice_id = v.choice_id)
                          where v.nick_id = ? and c.poll_id = ?)
        returning vote_id
    }, $choice_id, $message->sender->id, $poll_id);

    if ($vote && $vote->next) {
        $message->response->push(sprintf('Your ballot has been updated. To view poll results, use: (poll %d)', $poll_id));
    } else {
        $vote = $self->bot->config->db->do(q{
            insert into voting_votes ??? returning vote_id
        }, {
            choice_id => $choice_id,
            nick_id   => $message->sender->id,
        });

        if ($vote && $vote->next) {
            $message->response->push(sprintf('Your ballot has been cast. To view poll results, use: (poll %d)', $poll_id));
        } else {
            $message->response->raise('Could not record your vote. Please check your ballot and try again.');
        }
    }

    return;
}

sub voting_tally {
    my ($self, $message, $command, $rpl, $poll_id) = @_;

    unless ($message->has_channel) {
        $message->response->raise('Polls may only be conducted within channels.');
        return;
    }

    unless (defined $poll_id && $poll_id =~ m{^\d+$}) {
        $message->response->raise('You must supply a valid poll number. To see a list of current polls for this channel, use: (polls)');
        return;
    }

    my $poll = $self->bot->config->db->do(q{
        select * from voting_polls where poll_id = ? and channel_id = ?
    }, $poll_id, $message->channel->id);

    unless ($poll && $poll->next) {
        $message->response->raise('That poll number is not valid for this channel. To see the open polls in this channel, use: (polls)');
        return;
    }

    if ($poll->{'closed_at'}) {
        $message->response->raise('That poll has already closed. To view the results, use: (poll %d)', $poll_id);
        return;
    }

    unless ($poll->{'created_by'} == $message->sender->id) {
        $message->response->raise('Only the person who created a poll may close it and tally the votes. You did not create this poll.');
        return;
    }

    my $poll_close = $self->bot->config->db->do(q{
        update voting_polls set closed_at = now() where poll_id = ? and channel_id = ? and created_by = ? returning *
    }, $poll_id, $message->channel->id, $message->sender->id);

    unless ($poll_close && $poll_close->next) {
        $message->response->raise('Could not close the requested poll and tally results. Please try again.');
        return;
    }

    return $self->voting_poll($message, 'poll', $rpl, $poll_id);
}

__PACKAGE__->meta->make_immutable;

1;
