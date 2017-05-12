package TestDB::Schema::Result::Test;

use base qw ( DBIx::Class );
use strict;
use warnings;

__PACKAGE__->load_components ( qw ( Core ) );
__PACKAGE__->table ( "test" );
__PACKAGE__->add_columns (
  id => {
    data_type => "integer",
    is_nullable => 0,
    is_numeric => 1,
  },
  name => {
    data_type => "text",
    is_nullable => 0,
  },
);

1;
