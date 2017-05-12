package DBIx::ObjectMapper::SQL::Select;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::SQL::Base);

__PACKAGE__->initdata({
    column   => [],
    from     => [],
    where    => [],
    join     => [],
    order_by => [],
    group_by => [],
    limit    => 0,
    offset   => 0,
    having   => [],
    driver   => undef, # Pg, mysql, SQLite ...
});

__PACKAGE__->accessors({
    convert_columns_to_sql => [qw(column order_by group_by)],
    convert_tables_to_sql  => [qw(from)],
    convert_joins_to_sql   => [qw(join)],
    build_where            => [qw(where having)],
    num_check              => [qw(limit offset)],
});

sub as_sql {
    my $self = shift;
    my $mode = shift;

    my @bind;
    my ($from, @from_bind) = $self->from_as_sql;
    my $stm = 'SELECT ' . ($self->column_as_sql || '*') . ' FROM ' . $from;
    push @bind, @from_bind if @from_bind;

    my ($join_stm, @join_bind) = $self->join_as_sql;
    $stm .= ' ' . $join_stm if $join_stm;
    push @bind, @join_bind if @join_bind;

    my ($where_stm, @where_bind) = $self->where_as_sql;
    $stm .= ' WHERE ' . $where_stm if $where_stm;
    push @bind, @where_bind if @where_bind;

    if( my $group_by = $self->group_by_as_sql ) {
        $stm .= ' GROUP BY ' . $group_by;
    }

    my ($having_stm, @having_bind) = $self->having_as_sql;
    $stm .= ' HAVING ' . $having_stm if $having_stm;
    push @bind, @having_bind if @having_bind;

    if( my $order_by = $self->order_by_as_sql ) {
        $stm .= ' ORDER BY ' . $order_by;
    }

    if( $self->limit || $self->offset ) {
        my $method = $self->limit_syntax->{ lc( $self->{driver} ) };
        $method = $self->limit_syntax->{default}
            unless $method and $self->can($method);
        if( my $add_stm = $self->${method}() ) {
            $stm .= $add_stm;
        }
    }

    if( $mode and $mode eq 'parts' ) {
        $stm = '( ' . $stm . ' )';
    }

    return wantarray ? ($stm, @bind) : $stm;
}

1;

__END__
