package IRC::Schema::Result::Network;

use IRC::Schema::Result;

primary_column id => {
   data_type => 'int',
   is_auto_increment => 1,
};

column name => {
   data_type => 'varchar',
   size      => 100,
};

unique_constraint [qw( name )];

1;

