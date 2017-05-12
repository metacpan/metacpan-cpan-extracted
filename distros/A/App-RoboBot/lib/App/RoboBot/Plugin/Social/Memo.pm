package App::RoboBot::Plugin::Social::Memo;
$App::RoboBot::Plugin::Social::Memo::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

extends 'App::RoboBot::Plugin';

=head1 social.memo

Allows for saving short memos to be delivered to other users when they are next
observed by the bot.

=cut

has '+name' => (
    default => 'Social::Memo',
);

has '+description' => (
    default => 'Allows for saving short memos to be delivered to other users when they are next observed by the bot.',
);

has '+before_hook' => (
    default => 'check_memos',
);

=head2 memo

=head3 Description

Saves the message as a memo for the given nick, to be delivered to them when
the bot next sees them speak.

=head3 Usage

<nick> <message>

=head3 Examples

    (memo Beauford "update your jira tickets!")

=cut

has '+commands' => (
    default => sub {{
        'memo' => { method      => 'memo_save',
                    description => 'Saves the message as a memo for the given nick, to be delivered to them when the bot next sees them speak.',
                    usage       => '<nick> "<message>"' },
    }},
);

sub check_memos {
    my ($self, $message) = @_;

    # TODO have the retrieval memo limit use the same (to be added) global configuration
    # option as the output truncation in Response.pm

    my $res = $self->bot->config->db->do(q{
        select m.memo_id, m.message, to_char(m.created_at, 'YYYY-MM-DD HH24:MI') as created,
            n.name as sender
        from memo_memos m
            join nicks n on (n.id = m.from_nick_id)
        where m.to_nick_id = ?
            and m.delivered_at is null
        order by m.created_at asc
        limit 6
    }, $message->sender->id);

    return unless $res;

    # create a whole new Response object for sending the memos -- this prevents output
    # from an unrelated function also going to the private message, in case that's
    # what has triggered us hitting this method (i.e. a user had waiting memos and
    # the first thing they type in a channel is an S-Expression that has output
    # directed to the channel)
    my $memo_response = App::RoboBot::Response->new(
        bot  => $self->bot,
        nick => $message->sender,
    );

    $memo_response->push('The following memos were waiting for you:');

    my @memo_ids;

    while ($res->next) {
        $memo_response->push(sprintf('[%s] <%s> %s', $res->{'created'}, $res->{'sender'}, $res->{'message'}));
        push(@memo_ids, $res->{'memo_id'});
    }

    if (@memo_ids && @memo_ids > 0) {
        $self->bot->config->db->do(q{
            update memo_memos set delivered_at = now() where memo_id in ???
        }, \@memo_ids);

        $memo_response->send;
    }
}

sub memo_save {
    my ($self, $message, $command, $rpl, $nick, @args) = @_;

    unless (@args && @args > 0) {
        $message->response->raise('You must provide memo text to save.');
        return;
    }

    my $memo = join(' ', @args);

    if (length($memo) > 200) {
        $message->response->raise(sprintf('Your memo exceeds the 200 character limit, please shorten it. It was %d characters long.', length($memo)));
        return;
    }

    my $res = $self->bot->config->db->do(q{
        select id, name
        from nicks
        where lower(name) = lower(?)
    }, $nick);

    unless ($res && $res->next) {
        $message->response->raise(sprintf('The nick %s could not be located. Your memo has not been saved.', $nick));
        return;
    }

    my $nick_id = $res->{'id'};
    $nick = $res->{'name'};

    $res = $self->bot->config->db->do(q{
        insert into memo_memos ???
    }, {
        from_nick_id => $message->sender->id,
        to_nick_id   => $nick_id,
        message      => $memo,
        created_at   => 'now',
    });

    if ($res) {
        $message->response->push(sprintf('Your memo has been saved and will be delivered to %s when they next speak.', $nick));
    } else {
        $message->response->raise('An error was encountered while saving your memo. Please try again or contact an operator.');
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;
