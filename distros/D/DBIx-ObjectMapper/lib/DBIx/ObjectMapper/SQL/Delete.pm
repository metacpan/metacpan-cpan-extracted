package DBIx::ObjectMapper::SQL::Delete;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::SQL::Base);

__PACKAGE__->initdata({
    table => undef,
    where => [],
});

__PACKAGE__->accessors({
    convert_table_to_sql => [qw(table)],
    build_where          => [qw(where)],
});

sub as_sql {
    my $self = shift;
    my ( $stm, @bind );
    my ( $table_name, @no_bind ) = $self->table_as_sql;
    $stm .= 'DELETE FROM ' . $table_name;
    if( my ( $where_stm, @where_bind ) = $self->where_as_sql ) {
        $stm .= ' WHERE ' . $where_stm;
        push @bind, @where_bind;
    }

    return $stm, @bind;
}

1;
