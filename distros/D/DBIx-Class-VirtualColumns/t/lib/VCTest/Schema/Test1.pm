package # hide from PAUSE 
    VCTest::Schema::Test1;
   
use base 'DBIx::Class';
    
__PACKAGE__->load_components(qw/VirtualColumns PK::Auto Core/);
__PACKAGE__->table("test1");
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

__PACKAGE__->add_virtual_columns(
  'vcol1' => {
    test    => 'This is a test',  
  },
  'vcol2',
  'vcol3' => {
    accessor=> 'vcol3accessor',  
  },
);
    
1;
