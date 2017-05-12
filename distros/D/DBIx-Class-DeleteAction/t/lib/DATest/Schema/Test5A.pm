package # hide from PAUSE 
    DATest::Schema::Test5A;
   
use base 'DBIx::Class';
    
__PACKAGE__->load_components(qw/DeleteAction PK::Auto Core/);
__PACKAGE__->table("test5_A");
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
    'bs1' => 'DATest::Schema::Test5B', 
    { 'foreign.a1'  => 'self.id' },
    { 
        delete_action   => 'deleteall',
    }
);

__PACKAGE__->has_many(
    'bs2' => 'DATest::Schema::Test5B', 
    { 'foreign.a2'  => 'self.id' },
    { 
        delete_action   => 'deleteall',
    }
);


   
1;