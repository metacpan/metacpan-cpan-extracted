package DBIx::ActiveRecord::Arel::Query::Delete;
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

    $DBIx::ActiveRecord::Arel::Column::USE_FULL_NAME = 0;
    $DBIx::ActiveRecord::Arel::Column::AS = {};

    my $sql = 'DELETE FROM '.$self->main->table;
    my $where = $self->build_where;
    $sql .= " WHERE $where" if $where;
    $sql;
}

1;
