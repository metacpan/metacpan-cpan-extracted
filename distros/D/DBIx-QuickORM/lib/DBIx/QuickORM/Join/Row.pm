package DBIx::QuickORM::Join::Row;
use strict;
use warnings;

our $VERSION = '0.000014';

use Carp qw/croak/;

use constant ROW_DATA => 'row_data';

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Row';

use DBIx::QuickORM::Util::HashBase qw{
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

sub source { $_[0]->{+SOURCE}->() }
sub connection  { $_[0]->{+CONNECTION}->() }
sub row_data    { croak "Not Implemented" }

sub by_alias {
    my $self = shift;
    my ($as) = @_;

    croak "No subrows with alias '$as'" unless $self->source->components->{$as};

    return $self->{+BY_ALIAS}->{$as};
}

sub by_source {
    my $self = shift;
    my ($name) = @_;

    croak "No subrows for source '$name'" unless $self->source->lookup->{$name};

    @{$self->{+BY_SOURCE}->{$name} // []};
}

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

#<<<
sub stored_data   { +{ $_[0]->_row_map(sub { my $d = $b->stored_data;   map { ("$a.$_" => $d->{$_}) } keys %{$d} }) } }
sub pending_data  { +{ $_[0]->_row_map(sub { my $d = $b->pending_data;  map { ("$a.$_" => $d->{$_}) } keys %{$d} }) } }
sub desynced_data { +{ $_[0]->_row_map(sub { my $d = $b->desynced_data; map { ("$a.$_" => $d->{$_}) } keys %{$d} }) } }

sub is_desynced { $_[0]->_row_any(sub { $_->is_desynced }) }
sub has_pending { $_[0]->_row_any(sub { $_->has_pending }) }
sub in_storage  { $_[0]->_row_any(sub { $_->in_storage  }) }
sub is_stored   { $_[0]->_row_any(sub { $_->is_stored   }) }
sub is_invalid  { $_[0]->_row_any(sub { $_->is_invalid  }) }
sub is_valid    { $_[0]->_row_any(sub { $_->is_valid    }) }
#>>>

#####################
# {{{ Sanity Checks #
#####################

sub check_sync { $_[0]->_row_map(sub { $b->check_sync }); $_[0] }

#####################
# }}} Sanity Checks #
#####################

############################
# {{{ Manipulation Methods #
############################

sub update         { croak "Not Implemented" }
sub insert         { croak "Not Implemented" }
sub insert_or_save { croak "Not Implemented" }

#<<<
sub force_sync { $_[0]->_row_map(sub {$b->force_sync}); $_[0] }
sub discard    { $_[0]->_row_map(sub {$b->discard   }); $_[0] }
sub refresh    { $_[0]->_row_map(sub {$b->refresh   }); $_[0] }
sub save       { $_[0]->_row_map(sub {$b->save      }); $_[0] }
sub delete     { $_[0]->_row_map(sub {$b->delete    }); $_[0] }
#>>>

############################
# }}} Manipulation Methods #
############################

#####################
# {{{ Field methods #
#####################

sub _split_field { split( /\./, (@_ ? $_[0] : $_), 2 ) }

#<<<
sub field             { my $self = shift; my ($as, $f) = _split_field(shift); $self->{+BY_ALIAS}->{$as}->field($f, @_) }
sub raw_field         { my $self = shift; my ($as, $f) = _split_field(shift); $self->{+BY_ALIAS}->{$as}->raw_field($f, @_) }
sub stored_field      { my $self = shift; my ($as, $f) = _split_field(shift); $self->{+BY_ALIAS}->{$as}->stored_field($f, @_) }
sub pending_field     { my $self = shift; my ($as, $f) = _split_field(shift); $self->{+BY_ALIAS}->{$as}->pending_field($f, @_) }
sub raw_stored_field  { my $self = shift; my ($as, $f) = _split_field(shift); $self->{+BY_ALIAS}->{$as}->raw_stored_field($f, @_) }
sub raw_pending_field { my $self = shift; my ($as, $f) = _split_field(shift); $self->{+BY_ALIAS}->{$as}->raw_pending_field($f, @_) }
sub field_is_desynced { my $self = shift; my ($as, $f) = _split_field(shift); $self->{+BY_ALIAS}->{$as}->field_is_desynced($f, @_) }
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

sub insert_related { croak "Not Implemented" }
sub siblings       { croak "Not Implemented" }
sub follow         { croak "Not Implemented" }
sub obtain         { croak "Not Implemented" }

####################
# }}} Link methods #
####################

1;
