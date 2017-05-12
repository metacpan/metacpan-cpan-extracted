package DBIx::ActiveRecord::Arel::Query::Select;
use strict;
use warnings;
use base 'DBIx::ActiveRecord::Arel::Query';

sub _to_sql {
    my ($self) = @_;

    my $table = $self->has_join ? $self->main_table_with_alias : $self->main->table;
    my $sql = 'SELECT '.$self->build_select.' FROM ' . $table;
    my $join = $self->build_join;
    $sql .= ' '.$join if $join;
    my $where = $self->build_where;
    $sql .= " WHERE $where" if $where;
    my $ops .= $self->build_options;
    $sql .= " $ops" if $ops;
    $sql;
}

1;
