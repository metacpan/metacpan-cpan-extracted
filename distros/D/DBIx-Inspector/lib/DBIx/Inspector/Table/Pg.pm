package DBIx::Inspector::Table::Pg;
use strict;
use warnings;
use utf8;
use base qw/DBIx::Inspector::Table/;

# They return unquoted name.
# DBD::Pg v1.xx does not support these attribues,
# but don't you use such a old module, do you?
sub name   { $_[0]->{ PG_TABLE } }
sub schema { $_[0]->{ PG_SCHEMA } }

1;

