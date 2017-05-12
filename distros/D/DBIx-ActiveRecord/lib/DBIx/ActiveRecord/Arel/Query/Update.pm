package DBIx::ActiveRecord::Arel::Query::Update;
use strict;
use warnings;
use base 'DBIx::ActiveRecord::Arel::Query';

sub new {
    my ($self, $main, $hash, $columns) = @_;
    my $o = $self->SUPER::new($main);
    $o->merge($main->query);
    $o->{hash} = $hash;
    $o->{columns} = $columns;
    $o;
}

sub columns {shift->{columns}}
sub hash {shift->{hash}}

sub _to_sql {
    my ($self) = @_;

    $DBIx::ActiveRecord::Arel::Column::USE_FULL_NAME = 0;
    $DBIx::ActiveRecord::Arel::Column::AS = {};

    my @keys = $self->columns ? grep {exists $self->hash->{$_}} @{$self->columns} : keys %{$self->hash};
    my @set = map {$_.' = ?'} @keys;
    my $sql = 'UPDATE '.$self->main->table.' SET '.join(', ', @set);
    my $where = $self->build_where;
    $sql .= " WHERE $where" if $where;
    unshift @{$self->{binds}}, map {$self->hash->{$_}} @keys;
    $sql;
}

1;
