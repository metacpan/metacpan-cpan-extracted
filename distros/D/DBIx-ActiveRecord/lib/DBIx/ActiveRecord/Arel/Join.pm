package DBIx::ActiveRecord::Arel::Join;
use strict;
use warnings;

sub new {
    my ($self, $join_type, $primary_key_column, $foreign_key_column) = @_;
    bless {type => $join_type, pk => $primary_key_column, fk => $foreign_key_column}, $self;
}

sub build {
    my $self = shift;
    my $table = $self->{fk}->table->table;
    my $alias = $DBIx::ActiveRecord::Arel::Column::AS->{$table};
    $table .= " $alias" if $alias;
    $self->{type}.' '.$table.' ON '.$self->{fk}->name.' = '.$self->{pk}->name;
}

1;
