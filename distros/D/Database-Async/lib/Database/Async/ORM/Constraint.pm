package Database::Async::ORM::Constraint;

use strict;
use warnings;

our $VERSION = '0.013'; # VERSION

sub new {
    my ($class, %args) = @_;
    bless \%args, $class
}

sub table { shift->{table} }
sub name { shift->{name} }
sub type { shift->{type} }

sub is_deferrable { shift->{deferrable} }
sub is_deferred { shift->{initially_deferred} }

sub fields {
    my ($self) = @_;
    map { $self->table->field_by_name($_) } ($self->{fields} //= [])->@*
}

sub references {
    my ($self) = @_;
    $self->table->schema->table_by_name($self->{references}{table});
}

1;

