package DBIx::QuickORM::Role::Row;
use strict;
use warnings;

our $VERSION = '0.000020';

use Carp qw/croak/;
use List::Util qw/zip/;
use Scalar::Util qw/blessed/;

use Role::Tiny;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Role::Row - Role defining the common row interface.

=head1 DESCRIPTION

Shared behavior for row objects. Consumers provide the low-level state and
field accessors (storage state, desync tracking, the various field views);
this role builds the higher-level operations on top of them: insert / save /
delete, primary-key helpers, field metadata lookups, and link traversal
(C<follow>, C<obtain>, C<insert_related>, C<siblings>).

=head1 SYNOPSIS

    package My::Row;
    use Role::Tiny::With;
    with 'DBIx::QuickORM::Role::Row';

    sub source { ... }
    # ...and the other required methods

    $row->save;
    my @sibs = $row->siblings('some_link');

=head1 REQUIRED METHODS

Consumers must provide the state predicates and accessors (C<source>,
C<connection>, C<is_invalid>, C<is_valid>, C<in_storage>, C<is_desynced>,
C<has_pending>), the sync check (C<check_sync>), the manipulation primitives
(C<force_sync>, C<refresh>, C<discard>, C<update>), and the field views
(C<field>, C<raw_field>, C<fields>, C<raw_fields>, C<stored_field>,
C<pending_field>, C<raw_stored_field>, C<raw_pending_field>,
C<stored_fields>, C<pending_fields>, C<raw_stored_fields>,
C<raw_pending_fields>, C<field_is_desynced>).

=cut

requires qw{
    source
    connection
    is_invalid
    is_valid
    in_storage
    is_desynced
    has_pending
};

=pod

=head1 PUBLIC METHODS

=over 4

=item $bool = $row->track_desync

=item $bool = $row->is_stored

=item $dialect = $row->dialect

=item $bool = $row->has_field($name)

=item $affinity = $row->field_affinity($name)

=item @fields = $row->primary_key_field_list

=item @values = $row->primary_key_value_list

=item %pk = $row->primary_key_hash

=item $pk = $row->primary_key_hashref

Convenience accessors and primary-key helpers built on the source and
connection. C<has_field> croaks without a field name; the C<primary_key_*>
helpers croak (via C<check_pk>) when the source has no primary key.

=back

=cut

sub track_desync { 0 }
sub is_stored    { $_[0]->in_storage }
sub dialect      { $_[0]->connection->dialect }

sub has_field      { $_[0]->source->has_field($_[1] // croak "Must specify a field name") }
sub field_affinity { $_[0]->source->field_affinity($_[1], $_[0]->dialect) }

#<<<
sub primary_key_field_list { @{$_[0]->source->primary_key // []} }
sub primary_key_value_list { map { $_[0]->raw_stored_field($_) // undef } $_[0]->check_pk->primary_key_field_list }
sub primary_key_hash       { map { $_ => $_[0]->raw_stored_field($_) // undef } $_[0]->check_pk->primary_key_field_list }
sub primary_key_hashref    { +{ $_[0]->primary_key_hash } }
#>>>

=pod

=over 4

=item $handle = $row->handle(@args)

Return a handle scoped to this row's source and row.

=back

=cut

sub handle {
    my $self = shift;
    $self->connection->handle(source => $self->source, row => $self)->handle(@_);
}

=pod

=over 4

=item $str = $row->display

Human-readable identifier: the source name plus the primary-key values.

=back

=cut

sub display {
    my $self = shift;
    my $source = $self->source;
    return $source->source_orm_name . "(" . join(', ' => $self->primary_key_value_list) . ")";
}

=pod

=over 4

=item %args = $row->conflate_args($field, $value)

Return the argument list used for inflate/deflate of a single field value.

=back

=cut

sub conflate_args {
    my $self = shift;
    my ($field, $val) = @_;

    return (field => $field, value => $val, source => $self->source, dialect => $self->dialect, affinity => $self->field_affinity($field));
}

#####################
# {{{ Sanity Checks #
#####################

requires qw{
    check_sync
};

=pod

=over 4

=item $row = $row->check_pk

Return the row if its source has a primary key, otherwise croak.

=back

=cut

sub check_pk {
    return $_[0] if $_[0]->source->primary_key;

    croak "Operation not allowed: the table this row is from does not have a primary key";
}

#####################
# }}} Sanity Checks #
#####################

############################
# {{{ Manipulation Methods #
############################

requires qw{
    force_sync
    refresh
    discard
    update
};

=pod

=over 4

=item $row = $row->insert_or_save

Save the row if it is already stored, or insert it if it has pending data.

=item $row = $row->insert

Insert a not-yet-stored row that has pending data; croaks otherwise.

=item $row = $row->save

Write pending changes for a stored row. Checks the primary key and sync
state first; a no-op when there is nothing pending.

=item $row->delete

Delete the row from storage (requires a primary key).

=back

=cut

sub insert_or_save {
    my $self = shift;

    return $self->save(@_)   if $self->is_stored;
    return $self->insert(@_) if $self->has_pending;
}

sub insert {
    my $self = shift;

    croak "This row is already in the database" if $self->is_stored;
    croak "This row has no data to write" unless $self->has_pending;

    $self->connection->insert($self->source, $self);

    return $self;
}

sub save {
    my $self = shift;

    $self->check_pk;
    $self->check_sync;

    croak "This row is not in the database yet" unless $self->is_stored;

    my $pk = $self->source->primary_key or croak "Cannot use 'save()' on a row with a source that has no primary key";

    return $self unless $self->has_pending;

    $self->connection->update($self->source, $self);

    return $self;
}

sub delete {
    my $self = shift;

    $self->check_pk;

    $self->connection->delete($self->source, $self);
}

############################
# }}} Manipulation Methods #
############################

#####################
# {{{ Field methods #
#####################

requires qw{
    field
    raw_field
    fields
    raw_fields
    stored_field
    pending_field
    raw_stored_field
    raw_pending_field
    stored_fields
    pending_fields
    raw_stored_fields
    raw_pending_fields
    field_is_desynced
};


#####################
# }}} Field methods #
#####################

####################
# {{{ Link methods #
####################

=pod

=over 4

=item $handle = $row->follow($link)

Return a handle for the rows reached by following C<$link> from this row.

=item $row = $row->obtain($link)

Like C<follow>, but for a unique link: returns the single related row.

=item $row->insert_related($link, \%row_data)

Insert a related row across C<$link>, filling in the linking columns from
this row.

=item $handle = $row->siblings($link_or_fields)

Return a handle for rows sharing the same values on the given link's local
columns (or an explicit arrayref of fields); includes this row.

=back

=cut

sub follow {
    my $self = shift;
    my ($link) = @_;

    $link = $self->source->resolve_link($link);

    my $where = {};
    for my $set (zip($link->local_columns, $link->other_columns)) {
        my ($local, $other) = @$set;
        $where->{$other} = $self->field($local);
    }

    return $self->connection->handle($link->other_table, where => $where);
}

sub obtain {
    my $self = shift;
    my ($link) = @_;

    $link = $self->source->resolve_link($link);
    croak "The specified link does not point to a unique row" unless $link->unique;

    $self->follow($link)->one;
}

sub insert_related {
    my $self = shift;
    my ($link, $row_data) = @_;

    $link = $self->source->resolve_link($link);

    for my $set (zip($link->local_columns, $link->other_columns)) {
        my ($local, $other) = @$set;
        croak "field '$other' already exists in provided row data" if exists $row_data->{$other};
        $row_data->{$other} = $self->field($local);
    }

    $self->connection->insert($link->other_table() => $row_data);
}

sub siblings { # This includes the original
    my $self = shift;
    my ($link_or_fields) = @_;

    croak "You must specify a link or arrayref of fields to search on" unless $link_or_fields;

    my $fields;
    if (ref($link_or_fields) eq 'ARRAY') {
        $fields = $link_or_fields;
    }
    else {
        my $link = $self->source->resolve_link($link_or_fields);
        $fields = $link->local_columns;
    }

    my $where = +{ map { $_ => $self->field($_) } @$fields };
    return $self->handle(where => $where);
}

####################
# }}} Link methods #
####################

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
