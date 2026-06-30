package DBIx::QuickORM::Row;
use strict;
use warnings;

use Carp qw/confess croak/;
use Storable qw/dclone/;
use List::Util qw/zip/;
use Scalar::Util qw/blessed/;
use DBIx::QuickORM::Util qw/column_key/;

use DBIx::QuickORM::Affinity();
use DBIx::QuickORM::Link();

our $VERSION = '0.000026';

use DBIx::QuickORM::Connection::RowData qw{
    STORED
    PENDING
    DESYNC
    TRANSACTION
};

use Object::HashBase qw{
    +row_data
};

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Row';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Row - A single row of data backed by a source and connection.

=head1 DESCRIPTION

The concrete row class. It consumes L<DBIx::QuickORM::Role::Row>, which
supplies the higher-level operations (insert / save, primary-key helpers,
link traversal); this class supplies the low-level state and field
accessors that role builds on.

Row state is held in a row-data object (see
L<DBIx::QuickORM::Connection::RowData>) that tracks three views of the
data: C<STORED> (raw values as last seen in the database), C<PENDING>
(unsaved changes), and C<DESYNC> (fields whose stored value changed out
from under pending changes). Values are inflated/deflated through the
source's field types on demand.

=head1 SYNOPSIS

    my $name = $row->field('name');
    $row->field(name => 'New Name');
    $row->save;

    my $raw  = $row->raw_field('name');
    my $all  = $row->fields;

=head1 ATTRIBUTES

=over 4

=item row_data

The row-data object holding the C<STORED> / C<PENDING> / C<DESYNC> views
and transaction tracking. Required at construction.

=back

=head1 PUBLIC METHODS

=over 4

=item $bool = $row->track_desync

=item $source = $row->source

=item $conn = $row->connection

=item $obj = $row->row_data_obj

=item $data = $row->row_data

=item $stored = $row->stored_data

=item $pending = $row->pending_data

=item $desynced = $row->desynced_data

=item $bool = $row->is_invalid

=item $bool = $row->is_valid

=item $bool = $row->in_storage

=item $bool = $row->is_stored

=item $bool = $row->is_desynced

=item $bool = $row->has_pending

State predicates and accessors over the row-data object. C<row_data_obj>
returns the row-data object itself; C<row_data> returns its currently
active view.

=back

=cut

sub track_desync { 1 }

sub source { $_[0]->{+ROW_DATA}->source }
sub connection  { $_[0]->{+ROW_DATA}->connection }

sub row_data_obj { $_[0]->{+ROW_DATA} }
sub row_data { $_[0]->{+ROW_DATA}->active }

sub stored_data   { $_[0]->row_data->{+STORED} }
sub pending_data  { $_[0]->row_data->{+PENDING} }
sub desynced_data { $_[0]->row_data->{+DESYNC} }

sub is_invalid { $_[0]->{+ROW_DATA}->invalid // 0 }
sub is_valid   { $_[0]->{+ROW_DATA}->valid ? 1 : 0 }

sub in_storage  { my $a = $_[0]->{+ROW_DATA}->active(no_fatal => 1); $a && $a->{+STORED}  ? 1 : 0 }
sub is_stored   { my $a = $_[0]->{+ROW_DATA}->active(no_fatal => 1); $a && $a->{+STORED}  ? 1 : 0 }
sub is_desynced { my $a = $_[0]->{+ROW_DATA}->active(no_fatal => 1); $a && $a->{+DESYNC}  ? 1 : 0 }
sub has_pending { my $a = $_[0]->{+ROW_DATA}->active(no_fatal => 1); $a && $a->{+PENDING} ? 1 : 0 }

sub init {
    my $self = shift;

    confess "No 'row_data' provided" unless $self->{+ROW_DATA};
}

=pod

=over 4

=item $new = $row->clone(%overrides)

Return a new, unstored row carrying this row's data minus its primary-key
fields, deep-cloned, with any C<%overrides> applied on top.

=back

=cut

sub clone {
    my $self      = shift;
    my %overrides = @_;

    my $row_data = $self->row_data;
    my $data     = +{%{$row_data->{+STORED} // {}}, %{$row_data->{+PENDING} // {}}};

    # Remove primary key fields
    delete $data->{$_} for $self->primary_key_field_list;

    # Use dclone in case there is an inflated json object or similar that we do not want shared
    $data = dclone($data);

    # Add in any overrides
    %$data = (%$data, %overrides);

    return $self->handle->vivify($data);
}

#####################
# {{{ Sanity Checks #
#####################

=pod

=over 4

=item $row = $row->check_sync

Croak if the row is out of sync (a refresh changed stored values underneath
pending changes) and the class tracks desync (C<track_desync> is true, the
default for this class), or if the row's state predates the current
transaction stack; otherwise return the row. Use C<discard> or
C<force_sync> to resolve a desynced row.

=back

=cut

sub check_sync {
    croak <<"    EOT" if $_[0]->row_data->{+DESYNC} && $_[0]->track_desync;

This row is out of sync, this means it was refreshed while it had pending
changes and the data retrieved from the database does not match what was in
place when the pending changes were set.

To fix such conditions you need to either use row->discard() to clear the
pending changes, or you need to call ->force_sync() to clear the desync flags
allowing you to save the row despite the discrepency.

In addition it would be a good idea to call ->refresh() to have the most up to
date data.

    EOT

    return $_[0]->_check_stale;
}

#####################
# }}} Sanity Checks #
#####################

############################
# {{{ Manipulation Methods #
############################

=pod

=over 4

=item $row = $row->force_sync

Clear the desync flags so the row can be saved despite a detected
discrepancy.

=item $row = $row->refresh

Re-fetch the row from the database (requires a stored row with a primary
key). If the row no longer exists in the database it is invalidated and
this croaks.

=item $row = $row->discard

Drop pending changes and clear desync flags.

=item $row = $row->update(\%changes)

=item $row = $row->update(%changes)

Apply changes to the pending data and save the row. Croaks when a change
names a field the row does not have, or one owned by the database (a
generated column).

Updating a field clears that field's desync flag, so an update is an
explicit overwrite of a conflicting value. If a B<different> field is still
desynced the save will croak; resolving the full conflict (via C<discard>,
C<force_sync>, or updating every desynced field) is required first.

=item $row->delete

Delete the row from the database (requires a stored row with a primary
key).

=item $result = $row->cas($input, \%changes)

Compare-and-set this row: write the changes only while a set of guard values
still match, so a concurrent writer cannot overwrite it unnoticed. C<$input> is
the guard: a where hashref, an arrayref of field names, or a single field name
(field names are checked against the row's currently stored values). Returns a
L<DBIx::QuickORM::CAS::Result> that is true only when the row was updated; a
failed guard is a normal C<lost> result, not an exception. C<\%changes> should
set a new value for at least one guard column (C<cas> warns otherwise), for
example:

 my $result = $row->cas('version', {version => $row->field('version') + 1});

See the C<cas> method in L<DBIx::QuickORM::Handle> for the full description.

=back

=cut

sub force_sync {
    my $self = shift;
    delete $self->row_data->{+DESYNC};
    return $self;
}

# Fetch new data from the db
sub refresh {
    my $self = shift;

    $self->check_pk;

    croak "This row is not in the database yet" unless $self->is_stored;

    my $row = $self->connection->handle($self)->one;
    return $row if $row;

    $self->connection->state_invalidate(source => $self->source, row => $self, reason => "row no longer exists in the database");
    croak "Cannot refresh: this row no longer exists in the database";
}

# Remove pending changes (and clear desync)
sub discard {
    my $self = shift;

    delete $self->row_data->{+DESYNC};
    delete $self->row_data->{+PENDING};

    return $self;
}

sub delete {
    my $self = shift;

    $self->check_pk;

    croak "This row is not in the database yet" unless $self->is_stored;
    return $self->connection->handle($self)->delete;
}

sub cas {
    my $self = shift;
    my ($input, $changes) = @_;

    $self->check_pk;

    croak "This row is not in the database yet" unless $self->is_stored;
    return $self->connection->handle($self)->cas($input, $changes);
}

sub update {
    my $self = shift;

    my $changes;
    if (@_ == 1) {
        ($changes) = @_;
    }
    else {
        $changes = {@_};
    }

    $self->check_pk;

    my $source = $self->source;
    for my $field (keys %$changes) {
        croak "This row does not have a '$field' field" unless $source->has_field($field);
        croak "Cannot set field '$field': it is a database-generated column"
            if $source->field_is_generated($field);
    }

    $self->_check_stale;

    # Stage the changes against the current transaction so a rollback
    # discards them along with the transaction's frame.
    $self->{+ROW_DATA}->change_state({TRANSACTION() => $self->connection->current_txn, PENDING() => {%$changes}});

    my $row_data = $self->row_data;
    if (my $desync = $row_data->{+DESYNC}) {
        delete $desync->{$_} for keys %$changes;
        delete $row_data->{+DESYNC} unless keys %$desync;
    }

    $self->save();
    return $self;
}

############################
# }}} Manipulation Methods #
############################

#####################
# {{{ Field methods #
#####################

=pod

=over 4

=item $val = $row->field($name)

=item $row->field($name => $value)

=item $val = $row->raw_field($name)

Get (or, with a value, set) a single field. C<field> returns the inflated
value; C<raw_field> returns the deflated/raw value.

Setting a field stages the change against the current transaction (when one
is open), so rolling back that transaction or savepoint discards the staged
change.

Setting a field whose column is database-generated (C<GENERATED ALWAYS>,
stored or virtual) croaks: the database owns the value, so the ORM refuses to
stage a write that would be rejected at C<INSERT> / C<UPDATE> time. Reads are
unaffected.

=item $hash = $row->fields

=item $hash = $row->raw_fields

=item $val = $row->stored_field($name)

=item $val = $row->pending_field($name)

=item $val = $row->raw_stored_field($name)

=item $val = $row->raw_pending_field($name)

=item $hash = $row->stored_fields

=item $hash = $row->pending_fields

=item $hash = $row->raw_stored_fields

=item $hash = $row->raw_pending_fields

The various field views: C<fields> merges pending over stored; the
C<stored_*> / C<pending_*> variants read only that view, and the C<raw_*>
variants return deflated values instead of inflated ones.

=item $bool = $row->field_is_desynced($name)

True if the named field is marked out of sync.

=back

=cut

sub field     { my $self = shift; $self->_field(_inflated_field => @_) }
sub raw_field { my $self = shift; $self->_field(_raw_field      => @_) }

sub fields     { my $d = $_[0]->row_data; $_[0]->_fields(_inflated_field => $d->{+PENDING}, $d->{+STORED}) }
sub raw_fields { my $d = $_[0]->row_data; $_[0]->_fields(_raw_field      => $d->{+PENDING}, $d->{+STORED}) }

sub stored_field  { $_[0]->_inflated_field($_[0]->row_data->{+STORED},  $_[1]) }
sub pending_field { $_[0]->_inflated_field($_[0]->row_data->{+PENDING}, $_[1]) }

sub raw_stored_field  { $_[0]->_raw_field($_[0]->row_data->{+STORED},  $_[1]) }
sub raw_pending_field { $_[0]->_raw_field($_[0]->row_data->{+PENDING}, $_[1]) }

sub stored_fields      { $_[0]->_fields(_inflated_field => $_[0]->row_data->{+STORED}) }
sub pending_fields     { $_[0]->_fields(_inflated_field => $_[0]->row_data->{+PENDING}) }
sub raw_stored_fields  { $_[0]->_fields(_raw_field      => $_[0]->row_data->{+STORED}) }
sub raw_pending_fields { $_[0]->_fields(_raw_field      => $_[0]->row_data->{+PENDING}) }

sub field_is_desynced {
    my $self = shift;
    my ($field) = @_;

    croak "You must specify a field name" unless @_;

    my $desync = $self->row_data->{+DESYNC} or return 0;
    return $desync->{$field} // 0;
}

=pod

=head1 PRIVATE METHODS

=over 4

=item $row = $row->_check_stale

Croak when a transaction is open but this row's state predates the current
transaction stack; such a row must be refreshed before changes are staged.

=item $val = $row->_field($view_method, $name)

=item $row->_field($view_method, $name => $value)

Shared getter/setter behind C<field> / C<raw_field>: resolves the value
from pending or stored data (fetching a missing stored field on demand)
and runs it through C<$view_method>. When the on-demand fetch finds the
row gone from the database, the row is invalidated and this croaks.

=item $hash = $row->_fields($view_method, @data_hashes)

Build a field-name to value hash from the given data hashes using
C<$view_method>, earlier hashes winning.

=item $val = $row->_inflated_field($from, $name)

Return the inflated value of C<$name> from data hash C<$from>, inflating
and caching via the source's field type when needed.

=item $val = $row->_raw_field($from, $name)

Return the deflated/raw value of C<$name> from data hash C<$from>.

=back

=cut

sub _check_stale {
    my $self = shift;

    return $self unless $self->connection->current_txn;
    return $self if $self->row_data->{+TRANSACTION};

    croak <<"    EOT";

This row was fetched outside of the current transaction stack. The row has not
been refreshed since the new transaction stack started, meaning the data is
likely stale and unreliable. The row should be refreshed before making changes.
You can do this with a call to ->refresh().

    EOT
}

sub _field {
    my $self  = shift;
    my $meth  = shift;
    my $field = shift or croak "Must specify a field name";

    croak "This row does not have a '$field' field" unless $self->has_field($field);

    my $row_data = $self->row_data;

    if (@_) {
        croak "Cannot set field '$field': it is a database-generated column"
            if $self->source->field_is_generated($field);

        $self->check_pk if $row_data->{+STORED};    # We can set a field if the row has not been inserted yet, or if it has a pk
        $self->_check_stale;

        # Stage the edit against the current transaction so a rollback
        # discards it along with the transaction's frame.
        $self->{+ROW_DATA}->change_state({TRANSACTION() => $self->connection->current_txn, PENDING() => {$field => shift}});
        $row_data = $self->row_data;
    }

    return $self->$meth($row_data->{+PENDING}, $field) if $row_data->{+PENDING} && exists $row_data->{+PENDING}->{$field};

    if (my $st = $row_data->{+STORED}) {
        unless (exists $st->{$field}) {
            my $data = $self->connection->handle($self->source, where => $self->primary_key_hashref, fields => [$field])->data_only->one;

            unless ($data) {
                $self->connection->state_invalidate(source => $self->source, row => $self, reason => "row no longer exists in the database");
                croak "Cannot fetch field '$field': this row no longer exists in the database";
            }

            $st->{$field} = $data->{$field};
        }

        return $self->$meth($st, $field);
    }

    return undef;
}

sub _fields {
    my $self = shift;
    my $meth = shift;

    my %out;
    for my $hr (@_) {
        next unless $hr;

        for my $field (keys %$hr) {
            # An exists check, not //=, so a pending undef (staged NULL) is
            # not masked by a defined stored value.
            next if exists $out{$field};
            $out{$field} = $self->$meth($hr, $field);
        }
    }

    return \%out;
}

sub _inflated_field {
    my $self = shift;
    my ($from, $field) = @_;

    croak "This row does not have a '$field' field" unless $self->has_field($field);

    return undef unless $from;
    return undef unless exists $from->{$field};

    my $val = $from->{$field};

    return $val if ref($val);    # Inflated already

    if (my $type = $self->source->field_type($field)) {
        return $from->{$field} = $type->qorm_inflate($self->conflate_args($field, $val));
    }

    return $from->{$field};
}

sub _raw_field {
    my $self = shift;
    my ($from, $field) = @_;

    croak "This row does not have a '$field' field" unless $self->has_field($field);

    return undef unless $from;
    return undef unless exists $from->{$field};
    my $val = $from->{$field};

    return $val->qorm_deflate($self->conflate_args($field, $val))
        if blessed($val) && $val->can('qorm_deflate');

    if (my $type = $self->source->field_type($field)) {
        return $type->qorm_deflate($self->conflate_args($field, $val));
    }

    return $val;
}

#####################
# }}} Field methods #
#####################

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
