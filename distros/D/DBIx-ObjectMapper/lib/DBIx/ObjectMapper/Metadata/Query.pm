package DBIx::ObjectMapper::Metadata::Query;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use base qw(DBIx::ObjectMapper::Metadata::Table);

use Params::Validate qw(:all);
use Scalar::Util;
use List::MoreUtils;
use DBIx::ObjectMapper::Metadata::Table::Column::Type::Undef;

sub new {
    my $class = shift;

    my ( $name, $query, $param ) = validate_pos(
        @_,
        { type => SCALAR|ARRAYREF },
        { type => OBJECT, isa => 'DBIx::ObjectMapper::Query::Select' },
        { type => HASHREF, optional => 1 },
    );

    my $self = bless {
        table_name  => $name,
        query       => $query,
        columns     => [],
        column_map  => +{},
        engine      => $param->{engine} || $query->engine || undef,
        query_class => $param->{query_class} || $class->DEFAULT_QUERY_CLASS(),
        column_metaclass => $class->DEFAULT_COLUMN_METACLASS,
        primary_key => $param->{primary_key} || [],
        foreign_key => $param->{foreign_key} || [],
        unique_key  => $param->{unique_key}  || [],
    }, $class;

    my @columns;
    my %column_map;
    for my $c ( @{$query->builder->column} ) {
        my $col_obj = $self->_build_column($c)->as_alias($name);
        my $col_name = $col_obj->name;
        confess "$col_name already exists. use alias."
            if $column_map{$col_name};
        push @columns, $col_obj;
        $column_map{$col_name} = $#columns + 1;
    }

    $self->{columns} = \@columns;
    $self->{column_map} = \%column_map;

    return $self;
}

sub _build_column {
    my ( $self, $c ) = @_;

    if( ref $c eq $self->column_metaclass ) {
        return $c;
    }
    elsif( ref $c eq 'ARRAY' ) { # alias
        my $col_obj = $self->_build_column($c->[0]);
        $col_obj->{name} = $c->[1];
        return $col_obj;
    }
    elsif( ref $c eq 'HASH' ) { # function
        my $key = ( keys %$c )[0];
        return $self->column_metaclass->new(
            name  => $key,
            table => 'unknown',
            sep   => '.',
            type =>
                DBIx::ObjectMapper::Metadata::Table::Column::Type::Undef->new,
            is_nullable => 1,
        );
    }
    elsif( ref $c eq $self->column_metaclass . '::Func' ){
        my @funcs = @{$c->{func}};
        return $self->column_metaclass->new(
            name  => $funcs[$#funcs],
            table => 'unknown',
            sep   => '.',
            type =>
                DBIx::ObjectMapper::Metadata::Table::Column::Type::Undef->new,
            is_nullable => 1,
        );
    }
    else {
        confess "Can't convert column object: $c";
    }

}

=head2 table_name

=cut

sub table_name { $_[0]->{table_name} }

sub clone {
    my $self = shift;
    my $alias = shift;
    my $class = ref $self;
    return $class->new(
        $alias => $self->{query},
        {   engine      => $self->engine        || undef,
            query_class => $self->{query_class} || undef,
        }
    );
}

=head2 is_clone

=cut

sub is_clone { 0 }


=head2 primary_key

=cut

sub primary_key { $_[0]->{primary_key} }

=head2 unique_key

=cut

sub unique_key { $_[0]->{unique_key} }

=head2 foreign_key

=cut

sub foreign_key { $_[0]->{foreign_key} }

sub column {
    my $self = shift;

    if( @_ == 1 and !ref($_[0]) ) {
        my $name = shift;
        if( exists $self->column_map->{$name} ) {
            return $self->{columns}->[ $self->column_map->{$name} - 1 ];
        }
        else {
            return;
        }
    }
    elsif( @_ == 0 ) {
        return @{$self->columns};
    }
    else {
        confess '$obj->column(Scalar|Void)';
    }
}

sub columns    { $_[0]->{columns} }
sub column_map { $_[0]->{column_map} }

sub select {
    my $self = shift;
    return $self->query_object->select( $self->_select_query_callback )
        ->column( @{ $self->columns } )
        ->from( [ $self->{query}->builder, $self->table_name ] );
}


sub count {
    my $self = shift;
    return $self->query_object->count->from(
        [ $self->{query}->builder, $self->table_name ] );
}

sub insert { confess "INSERT is not suppurt." }

sub delete { confess "DELETE is not suppurt." }

sub update { confess "UPDATE is not suppurt." }

1;
