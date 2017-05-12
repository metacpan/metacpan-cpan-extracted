package # hide from PAUSE 
    TestSchema::Three::Result::Position;
   
use base 'DBIx::Class::Core';
    
__PACKAGE__->table("position");
__PACKAGE__->add_columns(
  "name"		=> { data_type => "varchar", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("name");


__PACKAGE__->has_many(
  "players",
  "TestSchema::Three::Result::Player",
  { "foreign.position" => "self.name" },
  { cascade_copy => 0, cascade_delete => 0 },
);


    
1;
