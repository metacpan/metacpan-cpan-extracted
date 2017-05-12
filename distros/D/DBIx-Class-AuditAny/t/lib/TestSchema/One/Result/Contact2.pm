package # hide from PAUSE 
    TestSchema::One::Result::Contact2;
   
use base 'DBIx::Class::Core';
    
__PACKAGE__->table("contact2");
__PACKAGE__->add_columns(
  "id"			=> { data_type => "integer", is_nullable => 0 },
  "nickname"	=> { data_type => "varchar", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");

    
1;
