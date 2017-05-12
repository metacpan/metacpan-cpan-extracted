package DBIx::ActiveRecord::Arel::Where;
use strict;
use warnings;

sub new {
    my ($self, $operator, $column, $value) = @_;
    bless {op => $operator, column => $column, value => $value}, $self;
}

sub op {shift->{op}}
sub column_name {shift->{column}->name}
sub value {shift->{value}}

sub build {
    my $self = shift;
    my $where;
    my @binds;
    if ($self->op eq 'IN' || $self->op eq 'NOT IN') {
        $where = $self->column_name.' '.$self->op.' ('.$self->value->placeholder.')';
        push @binds, $self->value->binds;
    } elsif ($self->op eq 'IS NULL' || $self->op eq 'IS NOT NULL') {
        $where = $self->column_name.' '.$self->op;
    } else {
        $where = $self->column_name.' '. $self->op.' '.$self->value->placeholder;
        push @binds, $self->value->binds;
    }
    return ($where, \@binds);
}

1;
