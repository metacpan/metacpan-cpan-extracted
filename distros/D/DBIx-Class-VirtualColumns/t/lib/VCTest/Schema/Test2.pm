package # hide from PAUSE 
    VCTest::Schema::Test2;
   
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/VirtualColumns PK::Auto Core/);
__PACKAGE__->table("test2");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    is_nullable => 0,
  },
  "name",
  {
    data_type => "varchar",
    is_nullable => 0,
  },
  "description",
  {
    data_type => "varchar",
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key('id');   
__PACKAGE__->might_have( test3 => 'VCTest::Schema::Test3', 'id' );

1;
