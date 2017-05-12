package DBIx::ActiveRecord::Arel::Query::Count;
use strict;
use warnings;
use base 'DBIx::ActiveRecord::Arel::Query';

sub new {
    my ($self, $main) = @_;
    my $o = $self->SUPER::new($main);
    $o->merge($main->query);
    $o;
}

sub _to_sql {
    my ($self) = @_;

    my $table = $self->has_join ? $self->main_table_with_alias : $self->main->table;
    my $sql = 'SELECT COUNT(*) FROM '.$table;
    my $join = $self->build_join;
    $sql .= ' '.$join if $join;
    my $where = $self->build_where;
    $sql .= " WHERE $where" if $where;
    $sql;
}

1;
