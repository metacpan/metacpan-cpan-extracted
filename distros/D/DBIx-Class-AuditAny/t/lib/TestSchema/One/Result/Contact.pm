package # hide from PAUSE 
    TestSchema::One::Result::Contact;
   
use base 'DBIx::Class::Core';
    
__PACKAGE__->table("contact");
__PACKAGE__->add_columns(
  "id"			=> { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "first"		=> { data_type => "varchar", is_nullable => 0, size => 32 },
  "last"			=> { data_type => "varchar", is_nullable => 0, size => 32 },
  "type_id"		=> { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");


__PACKAGE__->belongs_to(
  "type",
  "TestSchema::One::Result::ContactType",
  { id => "type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->might_have( contact2 => 'TestSchema::One::Result::Contact2', 'id' );

1;
