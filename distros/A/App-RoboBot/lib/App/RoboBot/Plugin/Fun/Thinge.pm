package App::RoboBot::Plugin::Fun::Thinge;
$App::RoboBot::Plugin::Fun::Thinge::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

extends 'App::RoboBot::Plugin';

=head1 fun.thinge

Provides generalized functions for saving, recalling, and tagging links,
funny cat pictures, quotes, or practically anything else that can be put into
a chat message.

The type of a thinge is arbitrary, and whenever a new thinge is added with a
type that is not yet known, that type is created automatically.

=cut

has '+name' => (
    default => 'Fun::Thinge',
);

has '+description' => (
    default => 'Provides generalized functions for saving, recalling, and tagging links, quotes, etc.',
);

=head2 thinge

=head3 Description

Returns a specific thinge (when the ``id`` is given), a random thinge with a
particular tag (when ``tag`` is given), or a random thinge of ``type`` from the
collection (when only ``type`` is provided).

=head3 Usage

<type> [<id> | <tag>]

=head2 thinge-find

=head3 Description

Searches through the thinges of a given type for any containing ``pattern``.
Patterns may be simple strings or regular expressions.

=head3 Usage

<type> <pattern>

=head2 thinge-add

=head3 Description

Saves a thinge to the collection and reports its ID. If there is no ``type``
yet, it is created automatically and a new ID sequence is started for it.

=head3 Usage

<type> <text>

=head2 thinge-counts

=head3 Description

Returns a map of thinges, where the keys are each thinge type's name and the
value is how many are in that thinge's collection for the current network.

=head2 thinge-delete

=head3 Description

Removes the specified thinge from the collection.

=head3 Usage

<type> <id>

=head2 thinge-tag

=head3 Description

Tags the specified thinge with the given list of tags. Tags will also start
with a ``#`` character - if you don't supply it, it will be added automatically
before saving the tag.

=head3 Usage

<type> <id> <tag> [<tag> ...]

=head2 thinge-types

=head3 Description

Lists the current types of thinges which have collections.

=head2 thinge-search

=head3 Description

Like ``(thinge-find)``, will search through the type of thinges specified, but
unlike find this function returns a summary of multiple matches. The ``limit``
argument may be used to change the number of matches shown (10 by default).

Search patterns are unanchored, case-insensitive regular expressions.

=head3 Usage

<type> <pattern> [<limit>]

=cut

has '+commands' => (
    default => sub {{
        'thinge' => { method      => 'thinge',
                      description => 'Returns a specific thinge (when the <id> is given), a random thinge with a particular tag (when <tag> is given), or a random thinge of <type> from the collection (when only <type> is provided).',
                      usage       => '<type> [<id> | <tag>]' },

        'thinge-find' => { method      => 'find_thinge',
                           description => 'Searches through the thinges of a given type for any containing the pattern <pattern>. Patterns may be simple strings or regular expressions.',
                           usage       => '<type> <pattern>', },

        'thinge-add' => { method      => 'save_thinge',
                          description => 'Saves a thinge to the collection and reports its ID.',
                          usage       => '<type> "<text>"' },

        'thinge-delete' => { method      => 'delete_thinge',
                             description => 'Removes the specified thinge from the collection.',
                             usage       => '<type> <id>' },

        'thinge-tag' => { method      => 'tag_thinge',
                          description => 'Tags the specified thinge with the given list of tags.',
                          usage       => '<type> <id> "<tag>" ["<tag 2>" ... "<tag N>"]' },

        'thinge-untag' => { method      => 'untag_thinge',
                          description => 'Untags the specified thinge with the given list of tags.',
                          usage       => '<type> <id> "<tag>" ["<tag 2>" ... "<tag N>"]' },

        'thinge-counts' => { method      => "show_type_counts",
                             description => 'Returns a map of thinges, where the keys are each thinge type\'s name and the value is how many are in that thinge\'s collection for the current network.',
                             usage       => '' },

        'thinge-types' => { method      => "show_types",
                            description => 'Lists the current types of thinges which have collections.',
                            usage       => '' },

        'thinge-search' => { method      => 'search_thinges',
                             description => 'Like (thinge-find), will search through the type of thinges specified, but unlike -find this function returns a summary of multiple matches. The <limit> argument may be used to change the number of matches shown (10 by default). Search patterns are unanchored, case-insensitive regular expressions.',
                             usage       => '<type> <pattern> [<limit>]' },
    }},
);

has 'type_ids' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

sub init {
    my ($self) = @_;

    my $res = $self->bot->config->db->do(q{
        select id, name
        from thinge_types
    });

    if ($res) {
        while ($res->next) {
            $self->type_ids->{$res->{'name'}} = $res->{'id'};
        }
    }
}

sub thinge {
    my ($self, $message, $command, $rpl, $type, $id_or_tag) = @_;

    my $type_id = $self->get_type_id($message, $type) || return;

    my ($res);

    if (defined $id_or_tag) {
        if ($id_or_tag =~ m{^\d+$}o) {
            $res = $self->bot->config->db->do(q{
                select t.id, t.thinge_num, t.thinge_url, n.name as nick,
                    to_char(t.added_at, 'FMDay, FMMonth FMDDth, YYYY') as added_date,
                    to_char(t.added_at, 'FMHH12:MIpm') as added_time
                from thinge_thinges t
                    join nicks n on (n.id = t.added_by)
                where t.type_id = ? and t.network_id = ? and t.thinge_num = ?
            }, $type_id, $message->network->id, $id_or_tag);
        } else {
            $id_or_tag =~ s{^\#+}{}ogs;

            $res = $self->bot->config->db->do(q{
                select t.id, t.thinge_num, t.thinge_url, n.name as nick,
                    to_char(t.added_at, 'FMDay, FMMonth FMDDth, YYYY') as added_date,
                    to_char(t.added_at, 'FMHH12:MIpm') as added_time
                from thinge_thinges t
                    join nicks n on (n.id = t.added_by)
                    join thinge_thinge_tags ttg on (ttg.thinge_id = t.id)
                    join thinge_tags tg on (tg.id = ttg.tag_id)
                where t.type_id = ? and t.network_id = ?
                    and lower(tg.tag_name) = lower(?)
                order by random()
                limit 1
            }, $type_id, $message->network->id, $id_or_tag);
        }
    } else {
        $res = $self->bot->config->db->do(q{
            select t.id, t.thinge_num, t.thinge_url, n.name as nick,
                to_char(t.added_at, 'FMDay, FMMonth FMDDth, YYYY') as added_date,
                to_char(t.added_at, 'FMHH12:MIpm') as added_time
            from thinge_thinges t
                join nicks n on (n.id = t.added_by)
            where t.type_id = ? and t.network_id = ?
            order by random()
            limit 1
        }, $type_id, $message->network->id);
    }

    unless ($res && $res->next) {
        $message->response->raise('Could not locate a %s that matched your request.', $type);
        return;
    }

    my @r = (
        sprintf('[%d]', $res->{'thinge_num'}),
        $res->{'thinge_url'},
    );

    $res = $self->bot->config->db->do(q{
        select tg.tag_name
        from thinge_tags tg
            join thinge_thinge_tags ttg on (ttg.tag_id = tg.id)
        where ttg.thinge_id = ?
        order by tg.tag_name asc
    }, $res->{'id'});

    my @tags;

    if ($res) {
        while ($res->next) {
            push(@tags, $res->{'tag_name'});
        }
    }

    if (@tags && @tags > 0) {
        push(@r, join(' ', map { "\#$_" } @tags));
    }

    return join(' ', @r);
}

sub find_thinge {
    my ($self, $message, $command, $rpl, $type, $pattern) = @_;

    return unless defined $type && defined $pattern;

    my $res = $self->bot->config->db->do(q{
        select t.thinge_num
        from thinge_thinges t
            join thinge_types tt on (tt.id = t.type_id)
            left join thinge_thinge_tags tttg on (tttg.thinge_id = t.id)
            left join thinge_tags tg on (tg.id = tttg.tag_id)
        where lower(tt.name) = lower(?)
            and t.network_id = ?
            and (t.thinge_url ~* ? or tg.tag_name ~* ?)
        group by t.thinge_num
        order by random()
        limit 1
    }, $type, $message->network->id, $pattern, $pattern);

    if ($res && $res->next) {
        # We found a thinge. Delegate displaying it to the normal thinge() method.
        return $self->thinge($message, $command, $rpl, $type, $res->{'thinge_num'});
    } else {
        # We could not find a matching thinge.
        $message->response->raise('Could not locate a %s that matched the pattern "%s".', $type, $pattern);
    }

    return;
}

sub search_thinges {
    my ($self, $message, $command, $rpl, $type, $pattern, $limit) = @_;

    $limit //= 10;

    unless (defined $type && defined $pattern) {
        $message->response->raise('Must supply a thinge type and a pattern for searching.');
        return;
    }

    my $res = $self->bot->config->db->do(q{
        select t.thinge_num, t.thinge_url
        from thinge_thinges t
            join thinge_types tt on (tt.id = t.type_id)
        where lower(tt.name) = lower(?)
            and t.thinge_url ~* ?
            and t.network_id = ?
        order by t.added_at desc
    }, $type, $pattern, $message->network->id);

    if ($res) {
        my $i;
        my $total = $res->count;

        for ($i = 0; $i < $limit && $res->next; $i++) {
            my $text = length($res->{'thinge_url'}) > 64
                ? substr($res->{'thinge_url'}, 0, 56) . '...'
                : $res->{'thinge_url'};

            $message->response->push(sprintf('[%d] %s', $res->{'thinge_num'}, $text));
        }

        $message->response->push(sprintf('Displayed %d match%s from a total of %d.',
            $i, ($i == 1 ? '' : 'es'), $total));
    }

    return;
}

sub save_thinge {
    my ($self, $message, $command, $rpl, $type, $text) = @_;

    return unless defined $text && $text =~ m{\w+}o;
    $text =~ s{(^\s+|\s+$)}{}ogs;

    my $type_id = $self->get_type_id($message, $type) || return;

    my $res = $self->bot->config->db->do(q{
        select id, thinge_num
        from thinge_thinges
        where type_id = ? and network_id = ? and lower(thinge_url) = lower(?)
    }, $type_id, $message->network->id, $text);

    if ($res && $res->next) {
        $message->response->push(sprintf('That %s has already been saved as #%d.', $type, $res->{'thinge_num'}));
        return;
    }

    $res = $self->bot->config->db->do(q{
        insert into thinge_thinges (type_id, network_id, thinge_url, added_by, added_at, thinge_num)
        values (?, ?, ?, ?, now(), (select coalesce(max(thinge_num) + 1, 1) from thinge_thinges where type_id = ? and network_id = ?))
        returning thinge_num
    }, $type_id, $message->network->id, $text, $message->sender->id, $type_id, $message->network->id);

    if ($res && $res->next) {
        $message->response->push(sprintf('Your %s has been saved to the collection as #%d.', $type, $res->{'thinge_num'}));
    } else {
        $message->response->raise('Could not save your %s. Please try again.', $type);
    }

    return;
}

sub delete_thinge {
    my ($self, $message, $command, $rpl, $type, $thinge_id) = @_;

    return unless defined $thinge_id && $thinge_id =~ m{^\d+$}o;

    my $type_id = $self->get_type_id($message, $type) || return;

    my $res = $self->bot->config->db->do(q{
        delete from thinge_thinges
        where type_id = ? and network_id = ? and thinge_num = ?
        returning id
    }, $type_id, $message->network->id, $thinge_id);

    if ($res && $res->next) {
        $message->response->push(sprintf('%s%s %d deleted.', uc(substr($type, 0, 1)), substr($type, 1), $thinge_id));
    } else {
        $message->response->raise('No such %s existed.', $type);
    }

    return;
}

sub tag_thinge {
    my ($self, $message, $command, $rpl, $type, $id, @tags) = @_;

    my $type_id = $self->get_type_id($message, $type) || return;

    # TODO: This is an ugly hack to get around the way &rest arguments in macros
    #       are joined (which is, itself, a hack to get around another problem).
    #       Whenever that macro problem is fixed, this should be undone.
    ($id, @tags) = grep { defined $_ } (split(/\s+/, $id), @tags);

    my $res = $self->bot->config->db->do(q{
        select id
        from thinge_thinges
        where type_id = ? and network_id = ? and thinge_num = ?
    }, $type_id, $message->network->id, $id);

    unless ($res && $res->next) {
        $message->response->raise('There is no such %s with an ID %d.', $type, $id);
        return;
    }

    my $thinge_id = $res->{'id'};

    my ($tag_id);

    foreach my $tag (@tags) {
        if (($tag_id, $tag) = $self->get_tag_id($message, $tag)) {
            $self->bot->config->db->do(q{
                insert into thinge_thinge_tags ???
            }, { thinge_id => $thinge_id, tag_id => $tag_id });
        }
    }

    $message->response->push(sprintf('%s%s has been tagged with %s.', uc(substr($type, 0, 1)), substr($type, 1),
        join(', ', map { "\#$_" } @tags)));

    return;
}

sub untag_thinge {
    my ($self, $message, $command, $rpl, $type, $id, @tags) = @_;

    my $type_id = $self->get_type_id($message, $type) || return;

    # TODO: This is an ugly hack to get around the way &rest arguments in macros
    #       are joined (which is, itself, a hack to get around another problem).
    #       Whenever that macro problem is fixed, this should be undone.
    ($id, @tags) = grep { defined $_ } (split(/\s+/, $id), @tags);

    my $res = $self->bot->config->db->do(q{
        select id
        from thinge_thinges
        where type_id = ? and network_id = ? and thinge_num = ?
    }, $type_id, $message->network->id, $id);

    unless ($res && $res->next) {
        $message->response->raise('There is no such %s with an ID %d.', $type, $id);
        return;
    }

    my $thinge_id = $res->{'id'};

    my ($tag_id);

    foreach my $tag (@tags) {
        if (($tag_id, $tag) = $self->get_tag_id($message, $tag)) {
            $self->bot->config->db->do(q{
                delete from thinge_thinge_tags
                where thinge_id = ? and tag_id = ?
            }, $thinge_id, $tag_id);
        }
    }

    $message->response->push(sprintf('%s%s has been untagged from %s.', uc(substr($type, 0, 1)), substr($type, 1),
        join(', ', map { "\#$_" } @tags)));

    return;
}

sub show_types {
    my ($self, $message) = @_;

    my $res = $self->bot->config->db->do(q{
        select tt.name
        from thinge_types tt
            join thinge_thinges t on (t.type_id = tt.id)
        where t.network_id = ?
        group by tt.name
        order by lower(name) asc
    }, $message->network->id);

    if ($res) {
        my @types;
        while ($res->next) {
            push(@types, $res->{'name'});
        }

        return @types;
    }

    return;
}

sub show_type_counts {
    my ($self, $message) = @_;

    my $res = $self->bot->config->db->do(q{
        select tt.name, count(*)
        from thinge_types tt
            join thinge_thinges t on (t.type_id = tt.id)
        where t.network_id = ?
        group by tt.name
        order by lower(name) asc
    }, $message->network->id);

    my %types;

    if ($res) {
        while ($res->next) {
            $types{$res->[0]} = $res->[1];
        }
    }

    return \%types;
}

sub get_tag_id {
    my ($self, $message, $tag) = @_;

    $tag =~ s{^\#+}{}ogs;
    $tag =~ s{(^\s+|\s+$)}{}ogs;
    $tag =~ s{\s+}{-}ogs;

    my $res = $self->bot->config->db->do(q{
        select id
        from thinge_tags
        where lower(tag_name) = lower(?)
    }, $tag);

    if ($res && $res->next) {
        return ($res->{'id'}, $tag);
    } else {
        $res = $self->bot->config->db->do(q{
            insert into thinge_tags ??? returning id
        }, { tag_name => $tag });

        if ($res && $res->next) {
            return ($res->{'id'}, $tag);
        }
    }

    return;
}

sub get_type_id {
    my ($self, $message, $type) = @_;

    my ($type_id);
    $type = lc($type);

    return $self->type_ids->{$type} if exists $self->type_ids->{$type};

    my $res = $self->bot->config->db->do(q{
        select id
        from thinge_types
        where lower(name) = lower(?)
    }, $type);

    if ($res && $res->next) {
        $type_id = $res->{'id'};
    } else {
        $res = $self->bot->config->db->do(q{
            insert into thinge_types ??? returning id
        }, { name => $type });

        if ($res && $res->next) {
            $type_id = $res->{'id'};
        } else {
            $message->response->raise('Could not locate an ID for thinge type: %s', $type);
            return;
        }
    }

    $self->type_ids->{$type} = $type_id;
    return $type_id;
}

__PACKAGE__->meta->make_immutable;

1;
