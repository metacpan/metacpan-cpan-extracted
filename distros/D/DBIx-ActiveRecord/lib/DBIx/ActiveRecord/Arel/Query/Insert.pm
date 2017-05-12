package DBIx::ActiveRecord::Arel::Query::Insert;
use strict;
use warnings;
use base 'DBIx::ActiveRecord::Arel::Query';

sub new {
    my ($self, $main, $hash, $columns) = @_;
    my $o = $self->SUPER::new($main);
    $o->{hash} = $hash;
    $o->{columns} = $columns;
    $o;
}

sub columns {shift->{columns}}
sub hash {shift->{hash}}

sub _to_sql {
    my ($self) = @_;

    my @keys = $self->columns ? grep {exists $self->hash->{$_}} @{$self->columns} : keys %{$self->hash};
    my $sql = 'INSERT INTO '.$self->main->table.' ('.join(', ', @keys).') VALUES ('.join(', ', map {'?'} @keys).')';
    $self->{binds} = [map {$self->hash->{$_}} @keys];
    $sql;
}

1;
