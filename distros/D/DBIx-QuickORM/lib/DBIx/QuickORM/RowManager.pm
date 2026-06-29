package DBIx::QuickORM::RowManager;
use strict;
use warnings;

our $VERSION = '0.000025';

use Carp qw/carp confess croak/;
use Scalar::Util qw/weaken/;
use DBIx::QuickORM::Util qw/load_class/;

use DBIx::QuickORM::Affinity();

use DBIx::QuickORM::Connection::RowData qw{
    STORED
    PENDING
    DESYNC
    TRANSACTION
    ROW_DATA
};

use Object::HashBase qw{
    transactions
    connection
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::RowManager - Base row manager mediating row state and storage.

=head1 DESCRIPTION

A row manager turns fetched/pending data sets into row objects and drives
their state transitions for insert, update, delete, and select against a
connection. It tracks the current transaction stack so newly created rows
are tagged with the active transaction.

This base class implements no caching: C<does_cache> is false and the cache
hooks are no-ops. L<DBIx::QuickORM::RowManager::Cached> subclasses it to add
a per-source identity cache.

=head1 SYNOPSIS

    my $mgr = DBIx::QuickORM::RowManager->new(connection => $connection);

    my $row = $mgr->select(source => $source, fetched => \%data);

=head1 ATTRIBUTES

=over 4

=item transactions

Arrayref of the connection's active transactions; defaults from the
connection. The last entry is the innermost active transaction.

=item connection

The owning connection (held weakly).

=back

=cut

sub init {
    my $self = shift;

    my $con = $self->{+CONNECTION} or croak "Connection was not provided";
    $self->{+TRANSACTIONS} //= $con->transactions;

    weaken($self->{+CONNECTION});
}

=pod

=head1 PUBLIC METHODS

=over 4

=item $bool = $mgr->does_cache

True if this manager keeps a row cache. False for the base class.

=item $mgr->cache($source, $row, $old_pk, $new_pk)

=item $row = $mgr->uncache($source, $row, $old_pk, $new_pk)

Cache hooks. No-ops in the base class; overridden by caching subclasses.

=cut

sub does_cache { 0 }

sub cache   { }
sub uncache { }

=pod

=item $row = $mgr->cache_lookup(source => $source, ...)

Look up a row in the cache. The row may be identified by fetched data, a
primary key, or a row object; fetched data is not required. Returns the
cached row or undef.

=cut

sub cache_lookup {
    my $self = shift;
    return $self->do_cache_lookup(($self->parse_params({@_}, fetched => 1))[0 .. 4]);
}

=pod

=item $row = $mgr->do_cache_lookup($source, $fetched, $old_pk, $new_pk, $row)

Backend cache lookup. Returns undef in the base class; caching subclasses
override it.

=cut

sub do_cache_lookup {
    my $self = shift;
    my ($source, $fetched, $old_pk, $new_pk, $row) = @_;
    return undef;
}

=pod

=item $mgr->invalidate(source => $source, row => $row, ...)

Mark a row's data invalid, both on any passed-in row and on the cached copy,
recording a reason (defaulting to the caller's file and line). The row can
be identified by a row object, fetched data, or a primary key; none of them
is individually required.

=cut

sub invalidate {
    my $self = shift;
    my ($source, $fetched, $old_pk, $new_pk, $row, $params) = $self->parse_params({@_}, fetched => 1);

    my $reason = $params->{reason};
    unless ($reason) {
        my @caller = caller;
        $reason = "$caller[1] line $caller[2]";
    }

    # Remove from passed in row if we got one
    $row->{+ROW_DATA}->invalidate(reason => $reason) if $row;

    # Now check cache for row, might be same, might not
    $row = $self->uncache($source, $row, $old_pk, $new_pk);
    $row->{+ROW_DATA}->invalidate(reason => $reason) if $row;

    return;
}

=pod

=item $state = $mgr->_state(%params)

Build a row-state hashref, tagging it with the innermost active transaction.

=cut

sub _state {
    my $self = shift;
    my %params = @_;

    $params{+TRANSACTION} //= $self->{+TRANSACTIONS}->[-1] if @{$self->{+TRANSACTIONS}};

    return \%params;
}

=pod

=item $row = $mgr->_vivify($source, $state)

Construct a new row object of the appropriate row class wrapping fresh row
data for the given state.

=cut

sub _vivify {
    my $self = shift;
    my ($source, $state) = @_;
    my $connection = $self->{+CONNECTION};
    my $row_class = load_class($source->row_class // $connection->schema->row_class // 'DBIx::QuickORM::Row') or die $@;
    my $row_data = DBIx::QuickORM::Connection::RowData->new(stack => [$state], connection => $connection, source => $source);
    return $row_class->new(ROW_DATA() => $row_data);
}

=pod

=item $row = $mgr->vivify(source => $source, ...)

Ensure there is a row object to work with for the given data, like Perl's own
autovivification of a nested hash slot. This is a low-level primitive: it
hands back a row to operate on before the caller necessarily knows whether
that row is stored in the database.

If a row matching the data's primary key is already loaded, that existing row
is returned as-is (it already carries known state, so it wins). Otherwise a
new row is created with the supplied data as its pending (unsaved) state.

C<vivify> does B<not> query the database and does B<not> guarantee the row
exists there. On a cache hit the supplied data is B<not> applied to the
existing row; existing values win. If the supplied data would silently
overwrite-and-lose information that way (a non-primary-key field whose value
differs from the loaded row), a warning is emitted naming those fields. To
change a loaded row, fetch it and call C<< $row->update >>; to ensure a row
exists in the database, use the connection's C<find_or_insert> or
C<update_or_insert> helpers.

=cut

sub vivify {
    my $self = shift;
    my ($source, $fetched, $old_pk, $new_pk, $row) = $self->parse_params({@_}, fetched => 1);

    # Autovivification semantics: an already-loaded row wins, exactly as
    # accessing an existing hash slot returns its current value untouched.
    if ($row) {
        $self->_warn_vivify_discard($source, $fetched, $row);
        return $row;
    }

    return $self->_vivify($source, $self->_state(pending => $fetched));
}

=pod

=item $mgr->_warn_vivify_discard($source, $fetched, $row)

Warn when vivify returns an already-loaded row and the supplied data would
silently lose information: a non-primary-key field present in C<$fetched>
whose value differs from the loaded row's current value. Primary-key fields
(the identity that found the row) and matching values are not reported.

=cut

sub _warn_vivify_discard {
    my $self = shift;
    my ($source, $fetched, $row) = @_;

    my %is_pk = map { $_ => 1 } @{$source->primary_key // []};

    my $row_data = $row->row_data_obj;
    my $current  = $row->raw_fields;

    my @lost;
    for my $field (sort keys %$fetched) {
        next if $is_pk{$field};
        next unless $source->has_field($field);
        next if $row_data->compare_field($field, $fetched, $current, $source, $self->{+CONNECTION});
        push @lost => $field;
    }

    return unless @lost;

    carp "vivify() returned an already-loaded row for this primary key; the supplied data for "
        . join(', ', map { "'$_'" } @lost)
        . " differs from the loaded row and was not applied. To change a loaded row, fetch it and call ->update(); to ensure a row exists in the database, use the connection's find_or_insert() or update_or_insert() helpers";
}

=pod

=item $row = $mgr->insert(source => $source, fetched => \%data, ...)

=item $row = $mgr->update(source => $source, fetched => \%data, ...)

=item $row = $mgr->delete(source => $source, fetched => \%data, ...)

=item $row = $mgr->select(source => $source, fetched => \%data, ...)

Apply the named storage operation to a row (creating one if needed),
updating the cache accordingly, and return the row.

=item $row = $mgr->do_insert($source, $fetched, $old_pk, $new_pk, $row)

=item $row = $mgr->do_update($source, $fetched, $old_pk, $new_pk, $row)

=item $row = $mgr->do_delete($source, $fetched, $old_pk, $new_pk, $row)

=item $row = $mgr->do_select($source, $fetched, $old_pk, $new_pk, $row)

Backend state transitions invoked by the matching public method, after
parameters have been parsed. They change the row's state and skip cache
maintenance.

=cut

sub insert {
    my $self = shift;
    my ($source, $fetched, $old_pk, $new_pk, $row) = $self->parse_params({@_});

    $row = $self->do_insert($source, $fetched, $old_pk, $new_pk, $row);
    $self->cache($source, $row, $old_pk, $new_pk);

    return $row;
}

sub do_insert {
    my $self = shift;
    my ($source, $fetched, $old_pk, $new_pk, $row) = @_;

    my $state = $self->_state(stored => $fetched, pending => undef);

    $row->{+ROW_DATA}->change_state($state) if $row;

    $row //= $self->_vivify($source, $state);

    return $row;
}

sub update {
    my $self = shift;
    my ($source, $fetched, $old_pk, $new_pk, $row) = $self->parse_params({@_});

    $row = $self->do_update($source, $fetched, $old_pk, $new_pk, $row);
    $self->cache($source, $row, $old_pk, $new_pk);

    return $row;
}

sub do_update {
    my $self = shift;
    my ($source, $fetched, $old_pk, $new_pk, $row) = @_;

    my $state = $self->_state(stored => $fetched, pending => undef, desync => undef);

    if ($row) {
        $row->{+ROW_DATA}->change_state($state);
    }
    else {
        $row = $self->_vivify($source, $state)
    }

    return $row;
}

sub delete {
    my $self = shift;
    my ($source, $fetched, $old_pk, $new_pk, $row) = $self->parse_params({@_}, fetched => 1);

    return unless $row;
    $row = $self->do_delete($source, $fetched, $old_pk, $new_pk, $row);
    $self->uncache($source, $row, $old_pk, $new_pk);

    return $row;
}

sub do_delete {
    my $self = shift;
    my ($source, $fetched, $old_pk, $new_pk, $row) = @_;

    $row->{+ROW_DATA}->change_state($self->_state(stored => undef));

    return $row;
}

sub select {
    my $self = shift;
    my ($source, $fetched, $old_pk, $new_pk, $row) = $self->parse_params({@_});

    $row = $self->do_select($source, $fetched, $old_pk, $new_pk, $row);
    $self->cache($source, $row, $old_pk, $new_pk);

    return $row;
}

sub do_select {
    my $self = shift;
    my ($source, $fetched, $old_pk, $new_pk, $row) = @_;

    my $state = $self->_state(stored => $fetched);

    # No existing row, make a new one
    return $self->_vivify($source, $state)
        unless $row;

    $row->{+ROW_DATA}->change_state($state);

    return $row;
}

=pod

=item ($source, $fetched, $old_pk, $new_pk, $row, $params) = $mgr->parse_params(\%params, %skip)

Validate and normalize the common operation parameters: confirm the source
role, extract old/new primary keys from the fetched data, validate any
passed-in row against the source and connection, and resolve a cached row.
Returns the unpacked values plus the original params hashref.

=cut

sub parse_params {
    my $self = shift;
    my ($params, %skip) = @_;

    my $source = $params->{source} or confess "'source' is a required parameter";
    confess "'$source' is not a valid query source" unless $source->DOES('DBIx::QuickORM::Role::Source');

    my $new_pk = $params->{new_primary_key};

    my $fetched = $params->{fetched};
    if ($fetched || !$skip{fetched}) {
        my @pk_vals;
        confess "'fetched' is a required parameter" unless $fetched;
        confess "'$fetched' is not a valid fetched data set" unless ref($fetched) eq 'HASH';

        # Rows come back keyed by database column name; restore ORM names so the
        # rest of the row layer is uniformly ORM-keyed. field_orm_name is
        # idempotent, so data that is already ORM-keyed is unaffected. Skip the
        # rebuild entirely when the source has no aliased columns.
        $fetched = $params->{fetched} = { map { $source->field_orm_name($_) => $fetched->{$_} } keys %$fetched }
            if $source->source_has_aliases;

        if (my $pk_fields = $source->primary_key) {
            my @bad;
            for my $field (@$pk_fields) {
                if (exists $fetched->{$field}) {
                    push @pk_vals => $fetched->{$field};
                }
                else {
                    push @bad => $field;
                }
            }

            if (@bad) {
                confess "The following primary key fields are missing from the fetched data: " . join(', ' => sort @bad)
                    unless $skip{fetched};
            }
            else {
                $new_pk //= \@pk_vals;
            }
        }
    }

    my $old_pk = $params->{old_primary_key};

    my $row;
    unless ($skip{row}) {
        if ($row = $params->{row}) {
            confess "'$row' is not a valid row"     unless $row->isa('DBIx::QuickORM::Row');
            confess "Row has incorrect source" unless $row->source == $source;
            confess "Row has incorrect connection"  unless $row->connection == $self->{+CONNECTION};
            $old_pk //= [$row->primary_key_value_list] if $row->in_storage;
        }

        my $cached = $self->do_cache_lookup($source, $fetched, $old_pk, $new_pk, $row);

        confess "Cached row does not match operating row" if $cached && $row && $cached != $row;
        $row //= $cached;
    }

    return ($source, $fetched, $old_pk, $new_pk, $row, $params);
}

=pod

=back

=cut

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
