package App::RoboBot::Plugin::Fun::Markov;
$App::RoboBot::Plugin::Fun::Markov::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use JSON;
use Lingua::EN::Tagger;
use List::Util qw( shuffle );

extends 'App::RoboBot::Plugin';

=head1 fun.markov

Analyzes channel messages and allows for creating markov chains based off chat
history.

=cut

has '+name' => (
    default => 'Fun::Markov',
);

has '+description' => (
    default => 'Analyzes channel messages and allows for creating markov chains based off chat history.',
);

has '+before_hook' => (
    default => 'parse_message',
);

=head2 markov

=head3 Description

Creates a sentence using HMM heuristics, based on selected nick(s) chat
history. Resulting grammar will be stilted, and the sentence will likely be
nonsensical, but should roughly resemble the style of the chosen target. If no
seed is chosen, a random one will be selected first from the chat history.

If the supplied nick is an asterisk ``*`` then markov modeling from all channel
participants will contribute to the final output.

This function currently uses a very poorly implemented modeller and produces
pretty awful output. Better implementations are welcome!

=head3 Usage

<nick | "*"> [<seed phrase>]

=cut

has '+commands' => (
    default => sub {{
        'markov' => { method      => 'generate_markov',
                      description => 'Creates a sentence using HMM heuristics, based on selected nick(s) chat history. Resulting grammar will be stilted, and the sentence will likely be nonsensical, but should roughly resemble the style of the chosen target. If no seed is chosen, a random one will be selected first from the chat history.',
                      usage       => '<nick[, nick, ...] | *> [<seed word or phrase>]',
                      example     => '"john, betty" waffles',
                      result      => 'Sunset waffles cooked heinously drove to Madagascar yesterday.' },
    }},
);

has 'tagger' => (
    is      => 'ro',
    isa     => 'Lingua::EN::Tagger',
    default => sub { Lingua::EN::Tagger->new() },
);

sub parse_message {
    my ($self, $message) = @_;

    return if $message->has_expression;

    my $text = $self->normalize_text($message->raw);
    return unless defined $text && length($text) > 0;

    my $tagged = $self->tagger->get_readable($text);
    my @phrases = $self->parse_phrases(\$tagged);

    return unless scalar(@phrases) > 0;

    $self->save_phrases($message, \@phrases);
    $self->save_sentence_form($message, $tagged);

    $self->compute_neighbors($message, \@phrases, $text);
    $self->save_neighbors($message, \@phrases);

    return;
}

sub generate_markov {
    my ($self, $message, $command, $rpl, $target, @args) = @_;

    my ($res, $seed);

    my @nick_ids;

    # Limit source nicks to just those who've spoken in a channel on the current
    # network, even when the target nick is specified by the sender.
    if (defined $target) {
        if ($target eq '*') {
            $res = $self->bot->config->db->do(q{
                select distinct(l.nick_id)
                from logger_log l
                    join channels c on (c.id = l.channel_id)
                    join networks n on (n.id = c.network_id)
                where n.id = ?
            }, $message->channel->network->id);

            if ($res) {
                while ($res->next) {
                    push(@nick_ids, $res->[0]);
                }
            }

            unless (scalar(@nick_ids) > 0) {
                $message->response->raise('No suitable nicks could be located for the source of the markov chain.');
                return;
            }
        } else {
            my @nicks = map { lc($_) } grep { defined $_ } split(/[,\s]+/, $target);

            $res = $self->bot->config->db->do(q{
                select distinct(n.id)
                from nicks n
                    join logger_log l on (l.nick_id = n.id)
                    join channels c on (c.id = l.channel_id)
                    join networks nt on (nt.id = c.network_id)
                where lower(n.name) in ??? and nt.id = ?
            }, \@nicks, $message->channel->network->id);

            if ($res) {
                while ($res->next) {
                    push(@nick_ids, $res->{'id'});
                }
            } else {
                $message->response->raise('Target nick "%s" could not be located.', $target);
                return;
            }
        }
    } else {
        $message->response->raise('Must provide a target nick to generate a markov chain.');
        return;
    }

    unless (scalar(@nick_ids) > 0) {
        $message->response->raise('Cannot generate markov chain without suitable nick source(s).');
        return;
    }

    # TODO make this properly work with multiple words (possibly by just matching
    # up the parts of speech with previously seen sentence forms, and using as
    # many of the words as possible that also match that nick's phrase corpus)

    if (@args) {
        $seed = $self->normalize_text(join(' ', grep { defined $_ && $_ =~ m{\w+}o } @args));

        $res = $self->bot->config->db->do(q{
            select *
            from markov_phrases
            where nick_id in ??? and phrase = ?
        }, \@nick_ids, $seed);

        if ($res && $res->next) {
            $seed = { map { $_ => $res->{$_} } $res->columns };
        }
    }

    unless (defined $seed && ref($seed) eq 'HASH') {
        # select a random seed phrase
        $res = $self->bot->config->db->do(q{
            select *
            from markov_phrases
            where nick_id in ???
            order by random()
            limit 1
        }, \@nick_ids);

        if ($res && $res->next) {
            $seed = { map { $_ => $res->{$_} } $res->columns };
        }
    }

    unless (defined $seed && ref($seed) eq 'HASH') {
        $message->response->raise('Cannot generate markov chain without a seed phrase.');
        return;
    }

    $res = $self->bot->config->db->do(q{
        with usemax as (select max(used_count) as m from markov_sentence_forms)
        select id, nick_id, structure, structure_jsonb,
            used_count, used_count::float / usemax.m * 100 * random()
        from markov_sentence_forms,
            usemax
        where nick_id in ???
            and jsonb_array_length(structure_jsonb) between 5 and 20
            and structure_jsonb \?& regexp_split_to_array(?, '[[:space:]]')
            and structure like ?
        order by 6 desc
        limit 1
    }, \@nick_ids,
       $seed->{'structure'},
       ('%' . $seed->{'structure'} . '%'),
    );

    unless ($res && $res->next) {
        $message->response->raise('Cannot locate a suitable sentence form for a markov chain.');
        return;
    }

    my $form = { map { $_ => $res->{$_} } $res->columns };

    my $chain = $self->fill_form(\@nick_ids, $form, $seed);

    return $self->humanize_text($chain);
}

sub humanize_text {
    my ($self, $text) = @_;

    $text =~ s{(^\s+|\s+$)}{}ogs;
    $text =~ s{\s+}{ }ogs;

    # TODO do more than just capitalizing the first letter and slapping a period on the end.
    $text = uc(substr($text, 0, 1)) . substr($text, 1);
    $text .= '.' unless substr($text, -1, 1) eq '.';

    return $text;
}

sub fill_form {
    my ($self, $nick_ids, $form, $seed) = @_;

    my ($l, $r) = $self->split_form_on_seed($form->{'structure'}, $seed);

    my @text = (split(/\s+/, $seed->{'phrase'}));

    # fill in the left hand side of the form, working our way backward from the seed phrase
    unshift(@text, $self->find_neighbor($nick_ids, $text[0], $_)) foreach reverse @{$l};

    # fill in the right hand side of the form, working out way forward from the seee phrase
    push(@text, $self->find_neighbor($nick_ids, $text[-1], $_)) foreach @{$r};

    return join(' ', @text);
}

sub find_neighbor {
    my ($self, $nick_ids, $source, $neighbor_pos) = @_;

    my $res = $self->bot->config->db->do(q{
        select p.phrase
        from markov_phrases s
            left join markov_neighbors n on (n.phrase_id = s.id)
            left join markov_phrases p on (p.id = n.neighbor_id)
        where s.phrase = ? and s.nick_id in ??? and p.structure = ?
        order by log(coalesce(occurrences + 1, 1)) + random() desc
        limit 1
    }, $source, $nick_ids, $neighbor_pos);

    return $res->[0] if $res && $res->next;

    $res = $self->bot->config->db->do(q{
        select p.phrase
        from markov_phrases p
        where p.nick_id in ??? and p.structure = ?
    }, $nick_ids, $neighbor_pos);

    return $res->[0] if $res && $res->next;

    return '';
}

sub split_form_on_seed {
    my ($self, $form, $seed) = @_;

    my @f = split(/\s+/, $form);

    my @candidates;

    for (my $i = 0; $i <= $#f; $i++) {
        push(@candidates, $i) if $f[$i] eq $seed->{'structure'};
    }

    my $pos = (shuffle @candidates)[0];

    my ($l, $r) = ([],[]);

    if ($pos > 0) {
        $l = [@f[0..($pos-1)]];
    }

    if ($pos < $#f) {
        $r = [@f[($pos+1)..$#f]];
    }

    return ($l,$r);
}

sub save_phrases {
    my ($self, $message, $phrases) = @_;

    foreach my $phrase (@{$phrases}) {
        my $res = $self->bot->config->db->do(q{
            update markov_phrases
            set used_count = used_count + 1,
                updated_at = now()
            where nick_id = ? and phrase = ?
            returning id
        }, $message->sender->id, $phrase->{'phrase'});

        next if $res && $res->next;

        $res = $self->bot->config->db->do(q{
            insert into markov_phrases ??? returning id
        }, { nick_id         => $message->sender->id,
             structure       => $phrase->{'structure'},
             phrase          => $phrase->{'phrase'},
             used_count      => 1,
        });
    }

    return 1;
}

sub save_neighbors {
    my ($self, $message, $phrases) = @_;

    my ($res, %phrase_ids);

    PHRASE:
    foreach my $phrase (@{$phrases}) {
        next unless exists $phrase->{'phrase'} && $phrase->{'phrase'} =~ m{\w+}o;

        my $phrase_id;

        if (exists $phrase_ids{$phrase->{'phrase'}}) {
            $phrase_id = $phrase_ids{$phrase->{'phrase'}};
        } else {
            $res = $self->bot->config->db->do(q{
                select id
                from markov_phrases
                where nick_id = ? and phrase ilike ?
                order by length(phrase) asc
                limit 1
            }, $message->sender->id, '%' . $phrase->{'phrase'});

            next PHRASE unless $res && $res->next;

            $phrase_id = $phrase_ids{$phrase->{'phrase'}} = $res->{'id'};
        }

        NEIGHBOR:
        foreach my $neighbor (@{$phrase->{'neighbors'}}) {
            next unless defined $neighbor && $neighbor =~ m{\w+}o;

            my $neighbor_id;

            if (exists $phrase_ids{$neighbor}) {
                $neighbor_id = $phrase_ids{$neighbor};
            } else {
                $res = $self->bot->config->db->do(q{
                    select id
                    from markov_phrases
                    where nick_id = ? and phrase ilike ?
                    order by length(phrase) asc
                    limit 1
                }, $message->sender->id, '%' . $neighbor);

                next NEIGHBOR unless $res && $res->next;

                $neighbor_id = $phrase_ids{$neighbor} = $res->{'id'};
            }

            $res = $self->bot->config->db->do(q{
                update markov_neighbors
                set occurrences = occurrences + 1,
                    updated_at = now()
                where phrase_id = ? and neighbor_id = ?
            }, $phrase_id, $neighbor_id);

            next NEIGHBOR if $res && $res->count > 0;

            $res = $self->bot->config->db->do(q{
                insert into markov_neighbors ???
            }, {
                phrase_id   => $phrase_id,
                neighbor_id => $neighbor_id,
                occurrences => 1,
            });
        }
    }
}

sub save_sentence_form {
    my ($self, $message, $form) = @_;

    return unless defined $form;

    my @parts_of_speech = $form =~ m{\b([A-Z]+)\b}og;

    $form = join(' ', @parts_of_speech);

    my $res = $self->bot->config->db->do(q{
        update markov_sentence_forms
        set used_count = used_count + 1,
            updated_at = now()
        where nick_id = ? and structure = ?
        returning id
    }, $message->sender->id, $form);

    return 1 if $res && $res->next;

    $res = $self->bot->config->db->do(q{
        insert into markov_sentence_forms ??? returning id
    }, { nick_id         => $message->sender->id,
         structure       => $form,
         structure_jsonb => encode_json([split(/\s+/, $form)]),
         used_count      => 1,
    });

    return 1;
}

sub compute_neighbors {
    my ($self, $message, $phrases, $text) = @_;

    foreach my $phrase (@{$phrases}) {
        if ($text =~ m{ (?:\s(\S+)\s)? $phrase->{'phrase'} (?:\s(\S+)\s)? }ix) {
            my ($l, $r) = ($1, $2);

            $phrase->{'neighbors'} = []
                unless exists $phrase->{'neighbors'}
                    && ref($phrase->{'neighbors'}) eq 'ARRAY';

            push(@{$phrase->{'neighbors'}}, $l) if defined $l && $l =~ m{\w+}o;
            push(@{$phrase->{'neighbors'}}, $r) if defined $r && $r =~ m{\w+}o;
        }
    }
}

sub parse_phrases {
    my ($self, $tagged) = @_;

    my @phrases = ();

    push(@phrases, $self->parse_nouns($tagged));
    push(@phrases, $self->parse_verbs($tagged));
    push(@phrases, $self->parse_descriptives($tagged));
    push(@phrases, $self->parse_misc($tagged));

    return @phrases;
}

sub parse_nouns {
    my ($self, $text) = @_;

    return unless defined $$text;

    my @phrases = ();

    my @np = $$text =~ m{
        \b(
            (?: \w+/NNS? \s*)+
        )\b
    }ogx;

    foreach my $ph (@np) {
        $ph =~ s{(^\s+|\s+$)}{}og;
        $$text =~ s{$ph}{N}g;

        my @words = grep { $_->{'type'} }
            map { $_ =~ m{\b(\w+)/(\w+)\b}o ? { type => $2, word => $1 } : {} }
            split(/\s+/, $ph);

        $ph = join(' ', map { $_->{'word'} } @words);

        push(@phrases, { structure => 'N', phrase => $ph }) if scalar(@words) > 1;
        push(@phrases, { structure => 'N',  phrase => $_->{'word'} }) for @words;
    }

    return @phrases;
}

sub parse_verbs {
    my ($self, $text) = @_;

    return unless defined $$text;

    my @phrases = ();

    my @np = $$text =~ m{
        \b(
            (?: \w+/VB.? \s*)+
        )\b
    }ogx;

    foreach my $ph (@np) {
        $ph =~ s{(^\s+|\s+$)}{}og;
        $$text =~ s{$ph}{V}g;

        my @words = grep { $_->{'type'} }
            map { $_ =~ m{\b(\w+)/(\w+)\b}o ? { type => $2, word => $1 } : {} }
            split(/\s+/, $ph);

        $ph = join(' ', map { $_->{'word'} } @words);

        push(@phrases, { structure => 'V', phrase => $ph }) if scalar(@words) > 1;
        push(@phrases, { structure => 'V',  phrase => $_->{'word'} }) for @words;
    }

    return @phrases;
}

sub parse_descriptives {
    my ($self, $text) = @_;

    return unless defined $$text;

    my @phrases = ();

    my @ap = $$text =~ m{
        \b(
            (?: \w+/JJR? \s*)+
        )\b
    }ogx;

    foreach my $ph (@ap) {
        $ph =~ s{(^\s+|\s+$)}{}og;
        $$text =~ s{$ph}{J}g;

        my @words = grep { $_->{'type'} }
            map { $_ =~ m{\b(\w+)/(\w+)\b}o ? { type => $2, word => $1 } : {} }
            split(/\s+/, $ph);

        $ph = join(' ', map { $_->{'word'} } @words);

        push(@phrases, { structure => 'J', phrase => $ph }) if scalar(@words) > 1;
        push(@phrases, { structure => 'J',  phrase => $_->{'word'} }) for @words;
    }

    return @phrases;
}

sub parse_misc {
    my ($self, $text) = @_;

    return unless defined $$text;

    my @phrases = ();

    my @words = grep { $_->{'type'} && $_->{'type'} !~ m{^(PP.?|POS)$}o }
        map { $_ =~ m{\b(\w+)/([A-Z]+)\b}o ? { type => $2, word => $1 } : {} }
        split(/\s+/, $$text);

    foreach my $word (@words) {
        $$text =~ s|$word->{'word'}/$word->{'type'}|$word->{'type'}|og;

        $word->{'word'} = 'not' if $word->{'word'} eq "n't"; # fixup from parsing
    }

    push(@phrases, { structure => $_->{'type'},  phrase => $_->{'word'} }) for @words;

    return @phrases;
}

sub normalize_text {
    my ($self, $text) = @_;

    # TODO fix tagging so that contractions aren't broken up into separate entities
    # (e.g. right now "isn't" gets tagged as "is/VBZ n't/RB" which may be useful for
    # some programs, but not ours")
    my %exp = (
        "won't"    => 'will not',
        "can't"    => 'can not',
        "isn't"    => 'is not',
        "wouldn't" => 'would not',
        "aren't"   => 'are not',
        "didn't"   => 'did not',
        "doesn't"  => 'does not',
        "don't"    => 'do not',
        "couldn't" => 'could not',
        "couldn't've" => 'could not have',
        "haven't"  => 'have not',
        "hasn't"   => 'has not',
        "how'd"    => 'how did',
        "how'll"   => 'how will',
        "how've"   => 'how have',
        "you've"   => 'you have',
        "you're"   => 'you are',
        "you'd"    => 'you had',
        "we've"    => 'we have',
        "we're"    => 'we are',
        "we'd"     => 'we had',
        "he'd"     => 'he had',
        "she'd"    => 'she had',
        "they've"  => 'they have',
        "they're"  => 'they are',
        "they'd"   => 'they had',
        # TODO add more
    );

    $text = lc($text);
    $text =~ s{[[:punct:]](\W|$)}{$1}g;
    $text =~ s{\b(\w+'\w+)\b}{exists $exp{$1} ? $exp{$1} : $1}gex;
    $text =~ s{\s+}{ }ogs;
    $text =~ s{(^\s+|\s+$)}{}ogs;

    return $text;
}

__PACKAGE__->meta->make_immutable;

1;
