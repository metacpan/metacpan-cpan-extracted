package Database::Async::ORM::Table;

use strict;
use warnings;

our $VERSION = '0.012'; # VERSION

sub new {
    my ($class, %args) = @_;
    bless \%args, $class
}

sub schema { shift->{schema} }
sub name { shift->{name} }
sub defined_in { shift->{defined_in} }
sub description { shift->{description} }
sub tablespace { shift->{tablespace} }
sub parents { (shift->{parents} //= [])->@* }
sub fields { (shift->{fields} //= [])->@* }
sub constraints { (shift->{constraints} //= [])->@* }
sub foreign_keys { grep { $_->type eq 'foreign_key' } shift->constraints }
sub primary_keys {
    my ($self) = @_;
    map { $self->field_by_name($_) } ($self->{primary_keys} // [])->@*
}

sub field_by_name {
    my ($self, $name) = @_;
    my ($field) = grep { $_->name eq $name } $self->fields;
    return $field;
}

1;

