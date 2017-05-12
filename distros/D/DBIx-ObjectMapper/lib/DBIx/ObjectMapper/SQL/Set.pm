package DBIx::ObjectMapper::SQL::Set;
use strict;
use warnings;

use base qw(DBIx::ObjectMapper::SQL::Base);

__PACKAGE__->initdata({
    sets     => +[],
    word     => undef,
    order_by => +[],
    group_by => +[],
    having   => +[],
    limit    => 0,
    offset   => 0,
    driver   => undef, # Pg, mysql, SQLite ...
});

__PACKAGE__->accessors({
    convert_columns_to_sql => [qw(order_by group_by)],
    build_where            => [qw(having)],
    num_check              => [qw(limit offset)],
});

sub sets {
    my $self = shift;
    $self->{sets} = \@_ if @_;
    return $self;
}

sub add_sets {
    my $self = shift;
    if( @_ ) {
        push @{$self->{sets}}, @_;
    }

    return $self;
}

sub as_sql {
    my $self = shift;

    my @bind;
    my $stm;
    my @list_stm;
    for my $list ( @{ $self->{sets} } ) {
        my ( $child_stm, @child_bind ) = $list->as_sql;
        push @bind, @child_bind;
        push @list_stm, $child_stm;
    }

    $stm .= join(
        ' ' . uc($self->{word}) . ' ',
        map { '( ' . $_ . ' )' } @list_stm
    );

    if( my $group_by = $self->group_by_as_sql ) {
        $stm .= ' GROUP BY ' . $group_by;
    }

    my ( $having_stm, @having_bind ) = $self->having_as_sql;
    $stm .= ' HAVING ' . $having_stm if $having_stm;
    push @bind, @having_bind if @having_bind;

    if( my $order_by = $self->order_by_as_sql ) {
        $stm .= ' ORDER BY ' . $order_by;
    }

    if( $self->limit || $self->offset ) {
        my $method = $self->limit_syntax->{ lc( $self->{driver} ) };
        $method = $self->limit_syntax->{default}
            unless $method and $self->can($method);
        $stm .= $self->${method}();
    }

    return wantarray ? ($stm, @bind) : $stm;
}

1;
