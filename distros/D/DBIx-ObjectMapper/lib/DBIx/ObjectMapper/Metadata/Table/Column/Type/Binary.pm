package DBIx::ObjectMapper::Metadata::Table::Column::Type::Binary;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::Metadata::Table::Column::Type);
use DBI qw(:sql_types);

sub set_engine_option {
    my ( $self, $engine ) = @_;
    $self->{escape_func} = $engine->driver->escape_binary_func($engine->dbh);
}

sub escape_func { $_[0]->{escape_func} }

sub to_storage {
    my ( $self, $val ) = @_;
    return $val unless defined $val;
    return $self->escape_func->($val);
}

1;
