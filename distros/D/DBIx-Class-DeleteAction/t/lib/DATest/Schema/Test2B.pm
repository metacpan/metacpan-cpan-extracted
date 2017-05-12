package # hide from PAUSE 
    DATest::Schema::Test2B;
   
use base 'DBIx::Class';
    
__PACKAGE__->load_components(qw/DeleteAction PK::Auto Core/);
__PACKAGE__->table("test2_b");
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

__PACKAGE__->has_many(
    'as' => 'DATest::Schema::Test2A', 
    { 'foreign.b'  => 'self.id' },
    { 
        delete_action   => 'null',
    }
);

__PACKAGE__->belongs_to(
    'c' => 'DATest::Schema::Test2C', 
    { 'foreign.id'  => 'self.c' },
    { 
        join_type       => 'left',
        delete_action   => 'testme',
    }
);

sub testme {
    my ($self,$params) = @_;
    if (defined $params->{extra}) {
        die('TESTME:'.$params->{extra});
    } else {
        warn('TESTME');
    }
    
}
   
1;