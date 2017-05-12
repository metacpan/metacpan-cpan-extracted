package # hide from PAUSE 
    DATest::Schema::Test3A;
   
use base 'DBIx::Class';
    
__PACKAGE__->load_components(qw/DeleteAction PK::Auto Core/);
__PACKAGE__->table("test3_A");
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
  "a",
  {
    data_type => "integer",
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key('id');   

__PACKAGE__->belongs_to(
    'a' => 'DATest::Schema::Test3A', 
    { 'foreign.id'  => 'self.a' },
    { 
        join_type       => 'left',
        delete_action   => 'delete',
    }
);

__PACKAGE__->has_many(
    'as' => 'DATest::Schema::Test3A', 
    { 'foreign.a'  => 'self.id' },
    { 
        delete_action   => 'delete',
    }
);


   
1;