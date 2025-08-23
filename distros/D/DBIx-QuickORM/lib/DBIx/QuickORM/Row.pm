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

our $VERSION = '0.000019';

use DBIx::QuickORM::Connection::RowData qw{
    STORED
    PENDING
    DESYNC
    TRANSACTION
};

use DBIx::QuickORM::Util::HashBase qw{
    +row_data
};

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Row';

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

sub check_sync {
    croak <<"    EOT" if $_[0]->{+DESYNC} && !$_[0]->track_desync;

This row is out of sync, this means it was refreshed while it had pending
changes and the data retrieved from the database does not match what was in
place when the pending changes were set.

To fix such conditions you need to either use row->discard() to clear the
pending changes, or you need to call ->force_sync() to clear the desync flags
allowing you to save the row despite the discrepency.

In addition it would be a good idea to call ->refresh() to have the most up to
date data.

    EOT

    croak <<"    EOT" if $_[0]->connection->current_txn && !$_[0]->row_data->{+TRANSACTION};

This row was fetched outside of the current transaction stack. The row has not
been refreshed since the new transaction stack started, meaning the data is
likely stale and unreliable. The row should be refreshed before making changes.
You can do this with a call to ->refresh().

    EOT

    return $_[0];
}

#####################
# }}} Sanity Checks #
#####################

############################
# {{{ Manipulation Methods #
############################

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
    return $self->connection->handle($self)->one;
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

    my $row_data = $self->row_data;
    for my $field (keys %$changes) {
        $row_data->{+PENDING}->{$field} = $changes->{$field};
        delete $row_data->{+DESYNC}->{$field} if $row_data->{+DESYNC};
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

sub field     { shift->_field(_inflated_field => @_) }
sub raw_field { shift->_field(_raw_field      => @_) }

sub fields     { my $d = $_[0]->row_data; $_[0]->_fields(_field     => $d->{+PENDING}, $d->{+STORED}) }
sub raw_fields { my $d = $_[0]->row_data; $_[0]->_fields(_raw_field => $d->{+PENDING}, $d->{+STORED}) }

sub stored_field  { $_[0]->_inflated_field($_[0]->row_data->{+STORED},  $_[1]) }
sub pending_field { $_[0]->_inflated_field($_[0]->row_data->{+PENDING}, $_[1]) }

sub raw_stored_field  { $_[0]->_raw_field($_[0]->row_data->{+STORED},  $_[1]) }
sub raw_pending_field { $_[0]->_raw_field($_[0]->row_data->{+PENDING}, $_[1]) }

sub stored_fields      { $_[0]->_fields(_field     => $_[0]->row_data->{+STORED}) }
sub pending_fields     { $_[0]->_fields(_field     => $_[0]->row_data->{+PENDING}) }
sub raw_stored_fields  { $_[0]->_fields(_raw_field => $_[0]->row_data->{+STORED}) }
sub raw_pending_fields { $_[0]->_fields(_raw_field => $_[0]->row_data->{+PENDING}) }

sub field_is_desynced {
    my $self = shift;
    my ($field) = @_;

    croak "You must specify a field name" unless @_;

    my $desync = $self->row_data->{+DESYNC} or return 0;
    return $desync->{$field} // 0;
}

sub _field {
    my $self  = shift;
    my $meth  = shift;
    my $field = shift or croak "Must specify a field name";

    croak "This row does not have a '$field' field" unless $self->has_field($field);

    my $row_data = $self->row_data;

    if (@_) {
        $self->check_pk if $row_data->{+STORED};    # We can set a field if the row has not been inserted yet, or if it has a pk
        $row_data->{+PENDING}->{$field} = shift;
    }

    return $self->$meth($row_data->{+PENDING}, $field) if $row_data->{+PENDING} && exists $row_data->{+PENDING}->{$field};

    if (my $st = $row_data->{+STORED}) {
        unless (exists $st->{$field}) {
            my $data = $self->connection->handle($self->source, where => $self->primary_key_hashref, fields => [$field])->data_only->one;
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
            $out{$field} //= $self->$meth($hr, $field);
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
