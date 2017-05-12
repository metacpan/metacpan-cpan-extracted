package # Hide from PAUSE
    VCTest::Schema::Test3;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/VirtualColumns PK::Auto Core/);
__PACKAGE__->table("test3");
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
);
__PACKAGE__->set_primary_key('id');   
    
1;
