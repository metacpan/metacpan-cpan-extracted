package # hide from PAUSE 
    DATest::Schema::Test2C;
   
use base 'DBIx::Class';
    
__PACKAGE__->load_components(qw/DeleteAction PK::Auto Core/);
__PACKAGE__->table("test2_c");
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
    'bs' => 'DATest::Schema::Test2B', 
    { 'foreign.c'  => 'self.id' },
    { 
        delete_action   => 'deny',
    }
);

__PACKAGE__->has_many(
    'ds' => 'DATest::Schema::Test2D', 
    { 'foreign.c'  => 'self.id' },
    { 
        delete_action   => 'ignore',
    }
);
   
1;