package App::RoboBot::Plugin::Fun::Factoid;
$App::RoboBot::Plugin::Fun::Factoid::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

extends 'App::RoboBot::Plugin';

=head1 fun.factoid

Exports functions for managing small snippets of keyword-based knowledge.

In addition to the exported functions, this module inserts a pre-hook which
inspects all messages for keywords which match the stored factoids.  Messages
in the general format of a question which contain matching keywords trigger an
automatic response from the bot with the stored factoid.

=cut

has '+name' => (
    default => 'Fun::Factoid',
);

has '+description' => (
    default => 'Allows for saving and retrieving small snippets of keyword-based knowledge.',
);

has '+before_hook' => (
    default => 'check_factoids',
);

=head2 add-factoid

=head3 Description

Creates a new factoid of ``name`` on the current network with the given
description. Descriptions are limited only by the restrictions of the current
network.

=head3 Usage

<factoid name> "<description>"

=head3 Examples

    (add-factoid perl "A language which looks the same before and after encryption.")

=head2 update-factoid

=head3 Description

Updates the description of the named factoid.

=head3 Usage

<factoid name> "<new description>"

=head3 Examples

    (update-factoid perl "A fine and upstanding member of the interpreted languages ecosystem.")

=head2 remove-factoid

=head3 Description

Removes the named factoid.

=head3 Usage

<factoid name>

=head3 Examples

    (remove-factoid perl)

=cut

has '+commands' => (
    default => sub {{
        'add-factoid' => { method      => 'add_factoid',
                           description => 'Adds snippets of information (replacing any that already exist for the given name).',
                           usage       => '"<name>" <... facts ...>' },

        'update-factoid' => { method      => 'add_factoid',
                              description => 'Updates an existing factoid, or creates a new one if there is no existing factoid by the same name.',
                              usage       => '"<name>" <... facts ...>' },

        'remove-factoid' => { method      => 'remove_factoid',
                              description => 'Removes the factoids stored under the given name.',
                              usage       => '"<name>"' },
    }},
);

sub check_factoids {
    my ($self, $message) = @_;

    return if $message->has_expression;

    my $bot_name = $message->network->nick->name;
    return unless defined $bot_name && $bot_name =~ m{\w+};

    return unless $message->raw =~ m{^\s*${bot_name}[:,]?\s+(?:what|who|where|when|why|how|is|are)\s+(.+)\?\s*$}i;

    my $query = lc($1);

    my $res = $self->bot->config->db->do(q{
        select id, name, factoid, ts_rank_cd(terms, query) as rank
        from factoids,
            plainto_tsquery(?) query
        where network_id = ?
            and query @@ terms
        order by rank desc
    }, $query, $message->network->id);

    # Silently return the pre-hook if there wasn't at least one matching factoid.
    return unless $res && $res->next;

    $message->response->push(
        sprintf('*%s*:', $res->{'name'}),
        $res->{'factoid'},
    );

    my @extras;

    # If there were other factoids that matches, gather up their names and IDs
    # to display after the highest ranked factoid.
    while ($res->next) {
        push(@extras, { id => $res->{'id'}, name => $res->{'name'} });
    }

    if (@extras > 0) {
        $message->response->push(sprintf('Additional factoids matched: %s',
            join(', ', map { sprintf('%s', $_->{'name'}) } @extras),
        ));
    }

    return;
}

sub add_factoid {
    my ($self, $message, $command, $rpl, $name, @factoids) = @_;

    return unless defined $name && @factoids && @factoids > 0;

    $name = $self->_normalize_name($name);
    return unless defined $name && length($name) > 0;

    my $fact_body = join("\n", @factoids);

    my $res = $self->bot->config->db->do(q{
        select *
        from factoids
        where network_id = ? and lower(name) = lower(?)
    }, $message->network->id, $name);

    if ($res && $res->next) {
        $res = $self->bot->config->db->do(q{
            update factoids
            set name       = ?,
                factoid    = ?,
                terms      = setweight(to_tsvector(?), 'A') || setweight(to_tsvector(?), 'B'),
                updated_by = ?,
                updated_at = now()
            where id = ?
            returning *
        }, $name, $fact_body, $name, $fact_body, $message->sender->id, $res->{'id'});

        if ($res && $res->next) {
            $message->response->push(sprintf('Factoid %s (%d) updated.', $res->{'name'}, $res->{'id'}));
        } else {
            $message->response->raise('Could not update existing factoid. Please try again.');
        }
    } else {
        $res = $self->bot->config->db->do(q{
            insert into factoids (network_id, name, factoid, created_by, terms) values
                (?, ?, ?, ?, setweight(to_tsvector(?), 'A') || setweight(to_tsvector(?), 'B'))
            returning *
        }, $message->network->id, $name, $fact_body, $message->sender->id, $name, $fact_body);

        if ($res && $res->next) {
            $message->response->push(sprintf('Factoid %s (%d) has been saved.', $res->{'name'}, $res->{'id'}));
        } else {
            $message->response->raise('Could not create factoid. Please try again.');
        }
    }

    return;
}

sub remove_factoid {
    my ($self, $message, $command, $rpl, $name) = @_;

    return unless defined $name;

    $name = $self->_normalize_name($name);
    return unless defined $name && length($name) > 0;

    my $res = $self->bot->config->db->do(q{
        delete from factoids where network_id = ? and lower(name) = lower(?)
    }, $message->network->id, $name);

    if ($res && $res->count > 0) {
        $message->response->push(sprintf('Factoid %s has been deleted.', $name));
    } else {
        $message->response->raise('Could not delete requested factoid. Please check the factoid name and try again.');
    }

    return;
}

sub _normalize_name {
    my ($self, $name) = @_;

    return unless defined $name && $name =~ m{\w+};

    $name =~ s{(^\s+|\s+$)}{}gs;
    $name =~ s{\s+}{ }gs;

    return lc($name);
}

__PACKAGE__->meta->make_immutable;

1;
