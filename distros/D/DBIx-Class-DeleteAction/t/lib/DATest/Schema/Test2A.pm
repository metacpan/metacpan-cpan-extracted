package # hide from PAUSE 
    DATest::Schema::Test2A;
   
use base 'DBIx::Class';
    
__PACKAGE__->load_components(qw/DeleteAction PK::Auto Core/);
__PACKAGE__->table("test2_a");
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
  "b",
  {
    data_type => "integer",
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key('id');   

__PACKAGE__->belongs_to(
    'b' => 'DATest::Schema::Test2B', 
    { 'foreign.id'  => 'self.b' },
    { 
        delete_action   => 'cascade',
    }
);
   
1;