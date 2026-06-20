package DBIx::Class::Relationship::ManyToMany::Async;

# ABSTRACT: many_to_many for DBIx::Class::Async — generates Future-returning
# accessor methods (groups, add_to_groups, remove_from_groups, set_groups).

use strict;
use warnings;

use Future;
use Exporter 'import';

our $VERSION = '0.01';
our @EXPORT = qw(many_to_many_async);


sub many_to_many_async {
    my ($class, $meth, $rel, $f_rel) = @_;

    $class->throw_exception("missing relation in many-to-many")   unless $rel;
    $class->throw_exception("missing foreign relation")           unless $f_rel;

    {
        no strict 'refs';
        no warnings 'redefine';

        my $add_meth    = "add_to_${meth}";
        my $remove_meth = "remove_from_${meth}";
        my $set_meth    = "set_${meth}";

        # ── $meth — list accessor (returns Future → arrayref of targets) ──
        # Single DB query: pivot rows with target prefetched via JOIN.
        # Each $_->$f_rel returns a Future resolved from memory (no extra query).
        {
            my $meth_name = join '::', $class, $meth;
            *$meth_name = sub {
                my $self = shift;
                return $self->search_related($rel, {}, { prefetch => $f_rel })->all
                    ->then(sub {
                        my $pivot_rows = shift;
                        my @futures    = map { $_->$f_rel } @$pivot_rows;
                        return Future->needs_all(@futures)
                            ->then(sub { [@_] })
                            if @futures;
                        return Future->done([]);
                    });
            };
        }

        # ── add_to_${meth} — link a target object (returns a Future) ──
        {
            my $add_meth_name = join '::', $class, $add_meth;
            *$add_meth_name = sub {
                my ($self, $obj, $link_vals) = @_;
                $obj
                    or $self->throw_exception("${add_meth} needs an object");

                my $rel_info = $self->result_source->relationship_info($rel);
                my %cond     = %{ $rel_info->{cond} };
                my ($fk_col, $self_col) = %cond;
                $fk_col   =~ s/^foreign\.//;
                $self_col =~ s/^self\.//;

                my $link = $self->search_related($rel)->new_result({
                    $fk_col    => $self->get_column($self_col),
                    %{ $link_vals // {} },
                });
                $link->set_from_related($f_rel, $obj);

                return $link->insert->then(sub { return $obj });
            };
        }

        # ── remove_from_${meth} — unlink a target object (returns a Future) ──
        {
            my $remove_meth_name = join '::', $class, $remove_meth;
            *$remove_meth_name = sub {
                my ($self, $obj) = @_;
                $self->throw_exception("${remove_meth} needs an object")
                    unless ref $obj;

                my $rel_source = $self->search_related($rel)->result_source;
                my %cond = %{ $rel_source->relationship_info($f_rel)->{cond} };
                my ($fk_col) = values %cond;
                $fk_col =~ s/^self\.//;

                return $self->search_related($rel, {
                    $fk_col => $obj->get_column('id')
                })->delete;
            };
        }

        # ── set_${meth} — replace all links (returns a Future) ──
        {
            my $set_meth_name = join '::', $class, $set_meth;
            *$set_meth_name = sub {
                my $self = shift;
                my @to_set = (ref($_[0]) eq 'ARRAY' ? @{ $_[0] } : @_);

                return $self->search_related($rel, {})->delete->then(sub {
                    my @futures = map { $self->$add_meth($_) } @to_set;
                    return Future->needs_all(@futures);
                });
            };
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Relationship::ManyToMany::Async - many_to_many for DBIx::Class::Async — generates Future-returning

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    # In MySchema::Result::User.pm
    __PACKAGE__->has_many(
        'user_group',
        'MySchema::Result::UserGroup',
        'user_id',
    );

    use DBIx::Class::Relationship::ManyToMany::Async;
    __PACKAGE__->many_to_many_async('groups', 'user_group', 'group');

    # In MySchema::Result::UserGroup.pm (the pivot)
    __PACKAGE__->belongs_to(
        'user',
        'MySchema::Result::User',
        { 'foreign.id' => 'self.user_id' },
    );
    __PACKAGE__->belongs_to(
        'group',
        'MySchema::Result::Group',
        { 'foreign.id' => 'self.group_id' },
    );

    # Usage from a controller
    my @groups = @{ $schema->await($user->groups) };
    say $_->name for @groups;

=head1 DESCRIPTION

Unlike L<DBIx::Class::Relationship::ManyToMany>, the standard
C<many_to_many> helper, this module generates accessor methods that
return L<Future> objects instead of blocking. This makes them
compatible with L<DBIx::Class::Async> worker pools.

The generated methods are named after the first argument passed to
C<many_to_many_async>. For example, with C<'groups'> as the first
argument, the following methods are created:

=over 4

=item C<groups>

Read accessor. Fetches all related target objects via a single JOIN
(prefetch on the pivot relationship). Returns a Future resolving to
an arrayref of target objects.

=item C<add_to_groups($target)>

Links a target object to the source row by inserting a pivot row.
Returns a Future resolving to the target object.

=item C<remove_from_groups($target)>

Unlinks a target object by deleting the corresponding pivot row.
Returns a Future.

=item C<set_groups(\\@targets)>

Replaces all links: deletes existing pivot rows, then inserts new ones.
Returns a Future.

=back

The underlying C<has_many> (pivot) and C<belongs_to> (target)
relationships must be declared in the Result classes before calling
C<many_to_many_async>. The method does not create them automatically.

=head2 Arguments

=over 4

=item C<$meth>

Accessor name. Generates C<${meth}>, C<add_to_${meth}>,
C<remove_from_${meth}>, and C<set_${meth}> methods.
Example: C<'groups'> produces C<groups>, C<add_to_groups>, etc.

=item C<$rel>

The C<has_many> relationship name from the source table to the pivot.
Example: C<'user_group'>.

=item C<$f_rel>

The C<belongs_to> relationship name from the pivot to the target table.
Example: C<'group'>.

=back

=head2 Limitations

The foreign table's primary key is assumed to be named C<id>.
Tables with custom PK names (e.g. C<idgroup>) are not yet supported.

SQL reserved words (C<group>, C<order>, etc.) used as the third argument
(C<$f_rel>) cause C<DBD::SQLite> errors in JOINs. Set C<quote_char> in
both the DBI attributes and the async options (value depends on the
database: C<\"> for SQLite/PostgreSQL, C<`> for MySQL):

    DBIx::Class::Async::Schema->connect(
        $dsn, $user, $pass,
        { quote_char => '\"', name_sep => '.' },
        { workers => 2, dbi_attrs => { quote_char => '\"' }, ... },
    );

Or use a non-reserved relationship name.

=head1 STATUS

B<EXPERIMENTAL.> This is a first release extracted from
L<Mojolicious::Plugin::Fondation::Model::DBIx::Async>. The API may
change. Feedback and bug reports welcome.

=head1 ACKNOWLEDGMENTS

This module was developed with significant assistance from an AI coding
agent. It is quite possible that I got lost in the intricacies of
L<DBIx::Class> and L<DBIx::Class::Async> — please be indulgent. All
remarks and observations are welcome.

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
