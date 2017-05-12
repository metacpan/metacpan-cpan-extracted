package DBIx::NoSQL::Search;
our $AUTHORITY = 'cpan:YANICK';
$DBIx::NoSQL::Search::VERSION = '0.0021';
use strict;
use warnings;

use Moose;
use Hash::Merge::Simple qw/ merge /;

has model => qw/ is ro required 1 /, handles => [qw/ store storage /];

has [qw/ _where /] => qw/ is rw isa Maybe[HashRef] /;
has [qw/ _order_by /] => qw/ is rw isa Maybe[ArrayRef] /;
has [qw/ _limit _offset /] => qw/ is rw /;

has cursor => qw/ is ro lazy_build 1 /;
sub _build_cursor {
    my $self = shift;
    $self->_cursor( 'value' );
}

sub _cursor {
    my $self = shift;
    my $target = shift;
    my ( $statement, @bind ) = $self->prepare( $target );
    return $self->storage->cursor( $statement, \@bind );
}

sub search {
    my $self = shift;
    return $self->where( @_ );
}

sub where {
    my $self = shift;
    my $where = shift;

    if ( my $_where = $self->_where ) {
        $where = merge $_where, $where;
    }

    return $self->clone( _where => $where ); 
}

sub order_by {
    my $self = shift;
    my $order_by = shift;

    $order_by = [ $order_by ] unless ref $order_by;

    if ( my $_order_by = $self->_order_by ) {
        $order_by = [ @$_order_by, @$order_by ];
    }

    return $self->clone( _order_by => $order_by ); 
}


sub clone {
    my $self = shift;
    my @override = @_;

    return ( ref $self )->new(
        model => $self->model,
        _where => $self->_where,
        _order_by => $self->_order_by,
        _limit => $self->_limit,
        _offset => $self->_offset,
        @override
    );
}

use DBIx::Class::SQLMaker;
sub prepare {
    my $self = shift;
    my $target = shift;

    $target = 'value' unless defined $target;

    my %options;
    if ( my $order_by = $self->_order_by ) {
        $options{ order_by } = $order_by;
    }

    my @where_order_limit_offset = (
        $self->_where,
        \%options,
        $self->_limit,
        $self->_offset,
    );

    my $maker = DBIx::Class::SQLMaker->new;

    my $entity_table = '__Store__';
    my $model_name = $self->model->name;
    my $search_table = $model_name;
    my $search_key_column = 'key';

    if      ( $target eq 'value' )  { $target = '__Store__.__value__' }
    elsif   ( $target eq 'count' )  { $target = 'COUNT(*)' }
    else                            { die "Invalid target ($target)" }

    my ( $statement, @bind ) = $maker->select(
        [
            { me => $search_table },
            [
                { '-join-type' => 'LEFT', '__Store__' => $entity_table },
                { "__Store__.__key__" => \"= me.$search_key_column", '__Store__.__model__' => \"= '$model_name'" },
                #{ "__Store__.__key__" => "me.$search_key_column", '__Store__.__model__' => "'$model_name'" },
            ]
        ],
        $target,
        @where_order_limit_offset,
    );

    return ( $statement, @bind );
}

sub all {
    my $self = shift;
    my %options = @_;

    my $model = $self->model;
    my $as = $options{ as } || 'object';

    my $cursor = $self->cursor;
    my $all = $self->cursor->all;

    if      ( $as eq 'object' ) { return map { $model->create_object( $_->[0] ) } @$all }
    elsif   ( $as eq 'entity' ) { return map { $model->create_entity( $_->[0] ) } @$all }
    elsif   ( $as eq 'data' ||
              $as eq 'hash' )   { return map { $model->create_data( $_->[0] ) } @$all }
    elsif   ( $as eq 'value' )  { return @$all }
    else                        { die "Invalid inflation target ($as)" }
}

sub next {
    my $self = shift;
    my %options = @_;

    my $model = $self->model;
    my $as = $options{ as } || 'object';

    my $cursor = $self->cursor;
    my $value = $cursor->next;

    # cursor returns an arrayref, we want its first element
    $value = $value->[0] if ref $value;

    # nothing found? eject
    return unless $value;

    if      ( $as eq 'object' ) { return $model->create_object( $value ) }
    elsif   ( $as eq 'entity' ) { return $model->create_entity( $value ) }
    elsif   ( $as eq 'data' ||
              $as eq 'hash' )   { return $model->create_data( $value ) }
    elsif   ( $as eq 'value' )  { return $value }
    else                        { die "Invalid inflation target ($as)" }
}

sub offset {
    my $self = shift;
    my $offset = shift;

    return $self->clone( _offset => $offset );
}

sub limit {
    my $self = shift;
    my $limit = shift;

    return $self->clone( _limit => $limit );
}

sub slice {
    my $self = shift;
    my $from = shift;
    my $to = shift;

    my $offset = $self->_offset || 0;

    $offset += $from;
    my $limit = $to ? ( $to - $from + 1 ) : 1;

    return $self->clone( _offset => $offset, _limit => $limit );
}

sub count {
    my $self = shift;

    my $cursor = $self->_cursor( 'count' );
    return unless my $result = $cursor->next;
    return $result->[0];
}

sub fetch {
    my $self = shift;
    return $self->all( as => 'data', @_ );
}

sub get {
    my $self = shift;
    return $self->all( @_ );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::NoSQL::Search

=head1 VERSION

version 0.0021

=head1 AUTHORS

=over 4

=item *

Robert Krimen <robertkrimen@gmail.com>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
