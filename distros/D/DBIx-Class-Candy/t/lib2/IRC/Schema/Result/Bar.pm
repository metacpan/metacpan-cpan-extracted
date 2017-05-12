package IRC::Schema::Result::User;

use DBIx::Class::Candy -autotable => v1, -base => 'IRC::Schema::Result';

column id => {
   data_type => 'int',
   is_auto_increment => 1,
};

unique_column handle => {
   data_type => 'varchar',
   size => 30,
};

primary_key 'id';

has_many messages => 'IRC::Schema::Result::Message', 'user_id';

1;
