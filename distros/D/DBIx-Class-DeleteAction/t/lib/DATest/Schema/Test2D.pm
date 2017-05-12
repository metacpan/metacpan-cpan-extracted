package # hide from PAUSE 
    DATest::Schema::Test2D;
   
use base 'DBIx::Class';
    
__PACKAGE__->load_components(qw/DeleteAction PK::Auto Core/);
__PACKAGE__->table("test2_d");
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
  "c",
  {
    data_type => "integer",
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key('id');   

__PACKAGE__->belongs_to(
    'c' => 'DATest::Schema::Test2C', 
    { 'foreign.id'  => 'self.c' },
    { 
        join_type       => 'left',
        delete_action   => 'delete',
    }
);

   
1;