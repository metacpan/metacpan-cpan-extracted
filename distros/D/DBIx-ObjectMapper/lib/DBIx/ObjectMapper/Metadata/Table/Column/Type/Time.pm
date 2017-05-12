package DBIx::ObjectMapper::Metadata::Table::Column::Type::Time;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::Metadata::Table::Column::Type::Datetime);

sub default_type { 'time' }

1;
