package # hide from PAUSE 
    DATest::Schema::Test1B;
   
use base 'DBIx::Class';
    
__PACKAGE__->load_components(qw/DeleteAction PK::Auto Core/);
__PACKAGE__->table("test1_b");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    is_nullable => 0,
  },
  "name",
  {
    data_type => "varchar",
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key('id');   

__PACKAGE__->has_many(
    'as' => 'DATest::Schema::Test1A', 
    { 'foreign.b'  => 'self.id' },
    { 
        delete_action   => 'null',
    }
);
   
1;