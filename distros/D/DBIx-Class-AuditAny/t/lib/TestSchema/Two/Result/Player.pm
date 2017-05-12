package # hide from PAUSE 
    TestSchema::Two::Result::Player;
   
use base 'DBIx::Class::Core';
    
__PACKAGE__->table("player");
__PACKAGE__->add_columns(
  "id"			=> { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "first"		=> { data_type => "varchar", is_nullable => 0, size => 32 },
  "last"			=> { data_type => "varchar", is_nullable => 0, size => 32 },
  "position"	=> { data_type => "varchar", is_nullable => 0, size => 32 },
  "team_id"		=> { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");


__PACKAGE__->belongs_to(
  "team",
  "TestSchema::Two::Result::Team",
  { id => "team_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->belongs_to(
  "position",
  "TestSchema::Two::Result::Position",
  { name => "position" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


1;
