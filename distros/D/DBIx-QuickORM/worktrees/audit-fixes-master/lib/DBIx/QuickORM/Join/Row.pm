package DBIx::QuickORM::Join::Row;
use strict;
use warnings;

our $VERSION = '0.000028';

use Carp qw/croak/;
use List::Util qw/first/;

use constant ROW_DATA => 'row_data';

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Row';

use Object::HashBase qw{
    +source
    +connection
    +by_alias
    +by_source
};

use DBIx::QuickORM::Connection::RowData qw{
    STORED
    PENDING
    DESYNC
    TRANSACTION
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Join::Row - A row representing a fetched join result.

=head1 DESCRIPTION

A row (see L<DBIx::QuickORM::Role::Row>) produced by fetching from a
L<DBIx::QuickORM::Join>. The flat join result is fractured into one underlying
row per joined component; this object holds those sub-rows and delegates field
and state queries to them, prefixing field names with their component alias
(C<alias.field>).

Field-level reads and bulk state queries (in storage, desynced, etc.) work
across all sub-rows. Manipulation and link-traversal methods are not
implemented for join rows and croak if called.

=head1 SYNOPSIS

    my $row = $connection->manager->select(source => $join, fetched => \%data);

    my $sub  = $row->by_alias('b');
    my @subs = $row->by_source('users');

    my $value = $row->field('b.name');

=head1 ATTRIBUTES

=over 4

=item source

Coderef returning the join source this row came from.

=item connection

Coderef returning the owning connection.

=item by_alias

Hashref mapping each component alias to its sub-row.

=item by_source

Hashref mapping each source name to an arrayref of its sub-rows.

=back

=cut

sub init {
    my $self = shift;

    my $row_data = delete $self->{+ROW_DATA} or croak "No row data";
    $self->{+SOURCE} = $row_data->{+SOURCE};
    $self->{+CONNECTION}  = $row_data->{+CONNECTION};

    my $join = $self->source;
    my $con  = $self->connection;

    for my $item (@{$join->fracture($row_data->active->{+STORED})}) {
        my $source = $item->{+SOURCE};
        my $row    = $con->manager->select(source => $source, fetched => $item->{data});
        $self->{+BY_ALIAS}->{$item->{as}} = $row;
        push @{$self->{+BY_SOURCE}->{$source->source_orm_name} //= []} => $row;
    }

    return;
}

=pod

=head1 PUBLIC METHODS

=over 4

=item $join = $row->source

The join source this row came from.

=item $con = $row->connection

The owning connection.

=item $row->row_data

Not implemented for join rows; croaks. A join row has no single row-data
object of its own.

=cut

sub source     { $_[0]->{+SOURCE}->() }
sub connection { $_[0]->{+CONNECTION}->() }

sub row_data {
    my $self = shift;
    croak "Not Implemented";
}

=pod

=item $sub = $row->by_alias($alias)

Return the sub-row for the given component alias. Croaks for an unknown
alias.

=cut

sub by_alias {
    my $self = shift;
    my ($as) = @_;

    croak "No subrows with alias '$as'" unless $self->source->components->{$as};

    return $self->{+BY_ALIAS}->{$as};
}

=pod

=item @subs = $row->by_source($name)

Return the sub-rows belonging to the named source. Croaks for an unknown
source.

=back

=cut

sub by_source {
    my $self = shift;
    my ($name) = @_;

    croak "No subrows for source '$name'" unless $self->source->lookup->{$name};

    @{$self->{+BY_SOURCE}->{$name} // []};
}

=pod

=head1 PRIVATE METHODS

=over 4

=item @out = $row->_row_map(\&cb)

Invoke the callback for each alias/sub-row pair (via C<$a>/C<$b>) and return
the flattened results.

=item $bool = $row->_row_any(\&cb)

True if the callback returns true for any sub-row.

=item $bool = $row->_row_all(\&cb)

True if the callback returns true for every sub-row.

=back

=cut

sub _row_map {
    my $self = shift;
    my ($cb) = @_;

    return map { local $a = $_; local $b = $self->{+BY_ALIAS}->{$_}; $cb->($a, $b) } keys %{$self->{+BY_ALIAS}};
}

sub _row_any {
    my $self = shift;
    my ($cb) = @_;

    return !!first { $cb->($_) } values %{$self->{+BY_ALIAS}};
}

sub _row_all {
    my $self = shift;
    my ($cb) = @_;

    return !first { !$cb->($_) } values %{$self->{+BY_ALIAS}};
}

=pod

=head1 PUBLIC METHODS (state)

=over 4

=item $data = $row->stored_data

=item $data = $row->pending_data

=item $data = $row->desynced_data

Merge the corresponding data from every sub-row into a single hashref keyed
by C<alias.field>.

=item $bool = $row->is_desynced

=item $bool = $row->has_pending

=item $bool = $row->in_storage

=item $bool = $row->is_stored

=item $bool = $row->is_invalid

True if the corresponding condition holds for any sub-row.

=item $bool = $row->is_valid

True only when every sub-row is valid, so a join row that contains an
invalidated sub-row is not reported as valid.

=back

=cut

#<<<
sub stored_data   { +{ $_[0]->_row_map(sub { my $d = $b->stored_data;   map { ("$a.$_" => $d->{$_}) } keys %{$d} }) } }
sub pending_data  { +{ $_[0]->_row_map(sub { my $d = $b->pending_data;  map { ("$a.$_" => $d->{$_}) } keys %{$d} }) } }
sub desynced_data { +{ $_[0]->_row_map(sub { my $d = $b->desynced_data; map { ("$a.$_" => $d->{$_}) } keys %{$d} }) } }

sub is_desynced { $_[0]->_row_any(sub { $_->is_desynced }) }
sub has_pending { $_[0]->_row_any(sub { $_->has_pending }) }
sub in_storage  { $_[0]->_row_any(sub { $_->in_storage  }) }
sub is_stored   { $_[0]->_row_any(sub { $_->is_stored   }) }
sub is_invalid  { $_[0]->_row_any(sub { $_->is_invalid  }) }
sub is_valid    { $_[0]->_row_all(sub { $_->is_valid    }) }
#>>>

#####################
# {{{ Sanity Checks #
#####################

=pod

=head1 PUBLIC METHODS (sanity checks)

=over 4

=item $row = $row->check_sync

Run C<check_sync> on every sub-row and return self.

=back

=cut

sub check_sync { $_[0]->_row_map(sub { $b->check_sync }); $_[0] }

#####################
# }}} Sanity Checks #
#####################

############################
# {{{ Manipulation Methods #
############################

=pod

=head1 PUBLIC METHODS (manipulation)

=over 4

=item $row->update

=item $row->insert

=item $row->insert_or_save

Not implemented for join rows; these croak.

=item $row = $row->force_sync

=item $row = $row->discard

=item $row = $row->refresh

=item $row = $row->save

=item $row = $row->delete

Apply the operation to every sub-row and return self.

=back

=cut

sub update {
    my $self = shift;
    croak "Not Implemented";
}

sub insert {
    my $self = shift;
    croak "Not Implemented";
}

sub insert_or_save {
    my $self = shift;
    croak "Not Implemented";
}

#<<<
sub force_sync { $_[0]->_row_map(sub {$b->force_sync}); $_[0] }
sub discard    { $_[0]->_row_map(sub {$b->discard   }); $_[0] }
sub refresh    { $_[0]->_row_map(sub {$b->refresh   }); $_[0] }
sub save {
    my $self = shift;
    # Save foreign-key parents before children (deterministic, not hash order).
    for my $as (@{$self->source->save_order}) {
        my $row = $self->{+BY_ALIAS}->{$as} or next;
        $row->save;
    }
    return $self;
}

sub delete {
    my $self = shift;
    # Delete children before parents (reverse of the save order).
    for my $as (reverse @{$self->source->save_order}) {
        my $row = $self->{+BY_ALIAS}->{$as} or next;
        $row->delete;
    }
    return $self;
}
#>>>

############################
# }}} Manipulation Methods #
############################

#####################
# {{{ Field methods #
#####################

=pod

=head1 PUBLIC METHODS (fields)

=over 4

=item $value = $row->field($proto, ...)

=item $value = $row->raw_field($proto, ...)

=item $value = $row->stored_field($proto, ...)

=item $value = $row->pending_field($proto, ...)

=item $value = $row->raw_stored_field($proto, ...)

=item $value = $row->raw_pending_field($proto, ...)

=item $bool  = $row->field_is_desynced($proto, ...)

Delegate to the sub-row named by the C<alias.field> proto, calling the
matching single-field accessor on it.

=item $data = $row->fields(@protos)

=item $data = $row->raw_fields(@protos)

=item $data = $row->stored_fields(@protos)

=item $data = $row->pending_fields(@protos)

=item $data = $row->raw_stored_fields(@protos)

=item $data = $row->raw_pending_fields(@protos)

Return a hashref of the requested C<alias.field> protos to their values,
pulled from the relevant sub-rows.

=back

=cut

sub _split_field { split( /\./, (@_ ? $_[0] : $_), 2 ) }

sub _subrow_field {
    my $self = shift;
    my ($method, $proto, @args) = @_;

    my ($as, $f) = _split_field($proto);

    # Unknown alias (typo or a bare proto with no alias) is a caller error;
    # a known alias whose sub-row was dropped by fracture (a LEFT-JOIN miss
    # where every column was NULL) is legitimately absent, so return undef.
    croak "No subrow with alias '$as' in this join" unless $self->source->components->{$as};
    my $sub = $self->{+BY_ALIAS}->{$as} or return undef;

    return $sub->$method($f, @args);
}

#<<<
sub field             { my $self = shift; $self->_subrow_field(field             => @_) }
sub raw_field         { my $self = shift; $self->_subrow_field(raw_field         => @_) }
sub stored_field      { my $self = shift; $self->_subrow_field(stored_field      => @_) }
sub pending_field     { my $self = shift; $self->_subrow_field(pending_field     => @_) }
sub raw_stored_field  { my $self = shift; $self->_subrow_field(raw_stored_field  => @_) }
sub raw_pending_field { my $self = shift; $self->_subrow_field(raw_pending_field => @_) }
sub field_is_desynced { my $self = shift; $self->_subrow_field(field_is_desynced => @_) }
#>>>

#<<<
sub fields             { my $self = shift; +{ map { my ($as, $f) = _split_field($_); ("$as.$f" => $self->{+BY_ALIAS}->{$as}->field($f)) } @_ }}
sub raw_fields         { my $self = shift; +{ map { my ($as, $f) = _split_field($_); ("$as.$f" => $self->{+BY_ALIAS}->{$as}->raw_field($f)) } @_ }}
sub stored_fields      { my $self = shift; +{ map { my ($as, $f) = _split_field($_); ("$as.$f" => $self->{+BY_ALIAS}->{$as}->stored_field($f)) } @_ }}
sub pending_fields     { my $self = shift; +{ map { my ($as, $f) = _split_field($_); ("$as.$f" => $self->{+BY_ALIAS}->{$as}->pending_field($f)) } @_ }}
sub raw_stored_fields  { my $self = shift; +{ map { my ($as, $f) = _split_field($_); ("$as.$f" => $self->{+BY_ALIAS}->{$as}->raw_stored_field($f)) } @_ }}
sub raw_pending_fields { my $self = shift; +{ map { my ($as, $f) = _split_field($_); ("$as.$f" => $self->{+BY_ALIAS}->{$as}->raw_pending_field($f)) } @_ }}
#>>>

#####################
# }}} Field methods #
#####################

####################
# {{{ Link methods #
####################

=pod

=head1 PUBLIC METHODS (links)

=over 4

=item $row->insert_related

=item $row->siblings

=item $row->follow

=item $row->obtain

Link traversal is not implemented for join rows; these croak.

=back

=cut

sub insert_related {
    my $self = shift;
    croak "Not Implemented";
}

sub siblings {
    my $self = shift;
    croak "Not Implemented";
}

sub follow {
    my $self = shift;
    croak "Not Implemented";
}

sub obtain {
    my $self = shift;
    croak "Not Implemented";
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
