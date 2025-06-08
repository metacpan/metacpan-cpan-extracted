package DBIx::QuickORM::Role::Row;
use strict;
use warnings;

use Carp qw/croak/;
use List::Util qw/zip/;
use Scalar::Util qw/blessed/;

use Role::Tiny;

requires qw{
    source
    connection
    is_invalid
    is_valid
    in_storage
    is_desynced
    has_pending
};

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

sub handle {
    my $self = shift;
    $self->connection->handle(source => $self->source, row => $self)->handle(@_);
}

sub display {
    my $self = shift;
    my $source = $self->source;
    return $source->source_orm_name . "(" . join(', ' => $self->primary_key_value_list) . ")";
}

#####################
# {{{ Sanity Checks #
#####################

requires qw{
    check_sync
};

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
