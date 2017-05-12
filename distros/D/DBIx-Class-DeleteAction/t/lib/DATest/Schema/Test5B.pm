package # hide from PAUSE 
    DATest::Schema::Test5B;
   
use base 'DBIx::Class';
    
__PACKAGE__->load_components(qw/DeleteAction PK::Auto Core/);
__PACKAGE__->table("test5_B");
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
  "a1",
  {
    data_type => "integer",
    is_nullable => 1,
  },
  "a2",
  {
    data_type => "integer",
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key('id');   

__PACKAGE__->belongs_to(
    'a1' => 'DATest::Schema::Test5A', 
    { 'foreign.id'  => 'self.a1' },
    { 
        delete_action   => 'delete',
    }
);

__PACKAGE__->belongs_to(
    'a2' => 'DATest::Schema::Test5A', 
    { 'foreign.id'  => 'self.a2' },
    { 
        delete_action   => 'ignore',
    }
);


   
1;