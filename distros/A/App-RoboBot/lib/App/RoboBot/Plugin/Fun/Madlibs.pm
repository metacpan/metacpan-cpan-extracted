package App::RoboBot::Plugin::Fun::Madlibs;
$App::RoboBot::Plugin::Fun::Madlibs::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

extends 'App::RoboBot::Plugin';

=head1 fun.madlibs

Just like being 6 years old and on a family road trip again.

=cut

use List::Util qw( shuffle );

has '+name' => (
    default => 'Fun::Madlibs',
);

has '+description' => (
    default => 'Just like being 6 years old and on a family road trip again.',
);

=head2 madlib

=head3 Description

=head3 Usage

[<id> <word1> ... <wordN>]

=head3 Examples

    :emphasize-lines: 2,3,5

    (madlib)
    A new madlib has been started for you. Please run the following command somewhere on this network to fill it in:
    (madlib 1 "noun" "verb" "noun" "daily event")
    (madlib 1 "user" "fill out" "super boring madlib" "lunch")
    "The user decided to fill out a super boring madlib before lunch."

=head2 create-madlib

=head3 Description

Creates a new madlib. The only argument should be the content of the madlib,
with placeholders marked between curly-braces.

Placeholder names are completely arbitrary, though they will be displayed to
anyone who gets your madlib to fill out. By default, every placeholder will
solicit a separate word from the user. If you wish to re-use the same word in
multiple places (say, a person's name or some other proper noun), you may add
index numbers to your placeholders. Any placeholders with the same index number
will re-use the same word.

Regular placeholders appear as::

    {word} {word} {word}

Which would request three separate words from the user.

Indexed placeholders are written::

    {word:0} {word:0} {word:1}

Which would request two words from the user, but the first one would be
repeated twice. The sequence of index numbers does not matter, just that they
are unique (internally, App::RoboBot will normalize them to a continuous integer
sequence beginning at ``0``, but you needn't actually care about that).

You may mix indexed and non-indexed placeholders in the same madlib text. The
non-indexed placeholders will automatically be assigned unique index numbers
internally.

When a user requests a madlib to fill out, the order of placeholders is
randomized each time. Thus, if your madlib requests three verbs, they may
not be filled back into the madlib in the same order each time it is filled
out.

=head3 Usage

<madlib text>

=head3 Examples

    (create-madlib "The {noun} decided to {verb} a {noun} before {daily event}.")

=head2 show-madlib

=head3 Description

Given the ID of a completed madlib (shown when a user fills out their madlib),
displays the completed madlib, otherwise picks one at random to display. Only
finished madlibs will be shown.

=head3 Usage

[<completed madlib ID>]

=cut

has '+commands' => (
    default => sub {{
        'madlib' => { method      => 'madlib',
                      description => 'Given no arguments, selects a madlib at random and requests a list of words from the user. Given arguments, places the provided words into the specified madlib and displays the results.',
                      usage       => '[<id> <word1> ... <wordN>]', },

        'create-madlib' => { method      => 'create_madlib',
                             description => 'Creates a new madlib. The only argument should be the content of the madlib, with placeholders marked between curly-braces.',
                             usage       => '"<text of madlib>"',
                             example     => '"The {noun} decided to {verb} a {noun} before {daily event}."', },

        'show-madlib' => { method      => 'show_madlib',
                           description => 'Given an <id>, displays the completed madlib, otherwise picks one at random to display. Only finished madlibs will be shown.',
                           usage       => '[<id>]', },
    }},
);

sub madlib {
    my ($self, $message, $command, $rpl, $id, @words) = @_;

    if (defined $id) {
        return $self->complete_madlib($message, $command, $id, @words);
    } else {
        return $self->start_madlib($message);
    }
}

sub complete_madlib {
    my ($self, $message, $command, $rpl, $id, @words) = @_;

    unless (@words && @words > 0) {
        $message->response->raise('You must supply words to complete a madlib.');
        return;
    }

    my $madlib = $self->bot->config->db->do(q{
        select m.*, mr.id as result_id, mr.nick_id
        from madlibs_madlibs m
            join madlibs_results mr on (mr.madlib_id = m.id)
        where mr.network_id = ? and mr.id = ? and mr.completed_at is null
    }, $message->network->id, $id);

    unless ($madlib && $madlib->next) {
        $message->response->raise('You have provided an invalid madlib ID (or it has already been completed). Please try again.');
        return;
    }

    unless ($madlib->{'nick_id'} == $message->sender->id) {
        $message->response->raise('You cannot fill out someone else\'s madlib. Use (madlib) to start your own.');
        return;
    }

    unless (scalar(@words) == scalar(@{$madlib->{'placeholders'}})) {
        # TODO: Provide a more intelligent error here that points out exactly
        #       the number (and PoS/type/name) of words that madlib requires.
        $message->response->raise('You have provided the wrong number of words for this madlib. Please try again.');
        return;
    }

    my @orig_words = @words;
    my $result = $madlib->{'madlib'};
    foreach my $pl (@{$madlib->{'placeholders'}}) {
        my $word = shift(@words);
        $result =~ s|{$pl}|$word|g;
    }

    my $res = $self->bot->config->db->do(q{
        update madlibs_results set ??? where id = ?
    }, {
        words        => \@orig_words,
        filled_in    => $result,
        completed_at => 'now',
    }, $madlib->{'result_id'});

    unless ($res) {
        $message->response->raise('There was an error saving your madlib results. Please try again.');
        return;
    }

    $message->response->push('Thank you for completing your madlib!');
    return $self->show_madlib($message, $command, $madlib->{'result_id'});
}

sub start_madlib {
    my ($self, $message) = @_;

    my $res = $self->bot->config->db->do(q{
        select *
        from madlibs_madlibs
        order by random() desc
        limit 1
    });

    unless ($res && $res->next) {
        $message->response->raise('There are no madlibs available.');
        return;
    }

    my $madlib = $self->bot->config->db->do(q{
        insert into madlibs_results ??? returning *
    }, {
        madlib_id   => $res->{'id'},
        network_id  => $message->network->id,
        nick_id     => $message->sender->id,
    });

    unless ($madlib && $madlib->next) {
        $message->response->raise('Could not start a madlib for you. Please try again.');
        return;
    }

    $message->response->push(sprintf('A new madlib has been started for you. Please run the following command somewhere on this network to fill it in:'));
    $message->response->push(sprintf('(madlib %d %s)', $madlib->{'id'}, join(' ', map { $_ =~ m|^([^:]+):|; "\"$1\"" } @{$res->{'placeholders'}})));

    return;
}

sub create_madlib {
    my ($self, $message, $command, $rpl, @madlib) = @_;

    unless (@madlib && @madlib > 0) {
        $message->response->raise('You must provide text for the new madlib.');
        return;
    }

    my $madlib_text = join(' ', @madlib);
    my @placeholders = $madlib_text =~ m|{([^}]+)}|g;

    unless (@placeholders && @placeholders > 0) {
        $message->response->raise('Your madlib should contain at least one placeholder.');
        return;
    }

    ($madlib_text, @placeholders) = $self->normalize_placeholders($madlib_text, @placeholders);

    unless (defined $madlib_text && @placeholders) {
        $message->response->raise('There was a problem normalizing your placeholders. Please try again.');
        return;
    }

    my $res = $self->bot->config->db->do(q{
        insert into madlibs_madlibs ??? returning *
    }, {
        madlib       => $madlib_text,
        placeholders => \@placeholders,
        created_by   => $message->sender->id,
    });

    if ($res && $res->next) {
        $message->response->push('Your madlib has been saved.');
    } else {
        $message->response->raise('There was a problem saving your madlib. Please try again.');
    }

    return;
}

sub show_madlib {
    my ($self, $message, $command, $rpl, $madlib_id) = @_;

    my $res;

    if (defined $madlib_id) {
        $res = $self->bot->config->db->do(q{
            select m.id, m.filled_in, m.completed_at, n.name as nick
            from madlibs_results m
                join nicks n on (n.id = m.nick_id)
            where m.id = ? and m.network_id = ? and m.filled_in is not null
        }, $madlib_id, $message->network->id);
    } else {
        $res = $self->bot->config->db->do(q{
            select m.id, m.filled_in, m.completed_at, n.name as nick
            from madlibs_results m
                join nicks n on (n.id = m.nick_id)
            where m.network_id = ? and m.filled_in is not null
            order by random() desc
            limit 1
        }, $message->network->id);
    }

    unless ($res && $res->next) {
        $message->response->raise('Could not find a completed madlib to display.');
        return;
    }

    return sprintf('[%d] <%s> %s', $res->{'id'}, $res->{'nick'}, $res->{'filled_in'});
}

sub normalize_placeholders {
    my ($self, $text, @placeholders) = @_;

    # At the end of this, every placeholder will have an index number (to support
    # the re-use of words throughout the text; e.g. a person's name repeated
    # consistently in a story). And every type of placeholder will have their
    # own sequence of index numbers. And all sequences will start at 0 and
    # increment by 1. So what starts out as {noun} will become {noun:0}. At the
    # same time, any placeholders that already have an index number will be
    # recognized and renumbered properly so that every original {noun:17} will
    # be renumbered to the same new index. This will make the complete_madlib
    # method much simpler.

    my $highest_index = 0;
    if (my @indices = sort { $b <=> $a } $text =~ m|[^:]+:(\d+)|g) {
        $highest_index = $indices[0];
    }

    foreach my $pl_name (@placeholders) {
        # Skip placeholders that have already been indexed.
        next if $pl_name =~ m|[^:]+:\d+|;

        my $old_name = "$pl_name";
        $pl_name = "$pl_name:".($highest_index++);

        # Replace the first occurrence of the unindexed name in the source text
        # with the newly indexed temporary name.
        $text =~ s|\{$old_name\}|\{$pl_name\}|;
    }

    my %type_index;
    @placeholders =
        map { [ "$_->[0]:$_->[1]", "$_->[0]:" . $type_index{$_->[0]}++ ] }
        sort { $a->[0] cmp $b->[0] || $a->[1] <=> $b->[1] }
        values %{
            { map {  $_ => [split(/:/, $_)] } @placeholders }
        };

    $text =~ s|{$_->[0]}|{$_->[1]}|g for @placeholders;

    return ($text, shuffle(map { $_->[1] } @placeholders));
}

__PACKAGE__->meta->make_immutable;

1;
