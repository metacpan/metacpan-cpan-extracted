package DBIx::ObjectMapper::Metadata::Table::Column;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::Metadata::Table::Column::Base);
use DBIx::ObjectMapper::Metadata::Table::Column::Func;

sub func {
    my $self = shift;
    return DBIx::ObjectMapper::Metadata::Table::Column::Func->new(
        $self,
        @_,
    );
}

1;
