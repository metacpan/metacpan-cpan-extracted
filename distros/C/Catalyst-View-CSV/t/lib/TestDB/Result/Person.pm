package TestDB::Result::Person;

use base qw ( DBIx::Class );
use strict;
use warnings;

__PACKAGE__->load_components ( qw ( Core ) );
__PACKAGE__->table ( "person" );
__PACKAGE__->add_columns (
  id => {
    data_type => "serial",
    is_numeric => 1,
    is_auto_increment => 1,
  },
  name => {
    data_type => "text",
  },
);

1;
