package # hide from PAUSE 
    TestSchema::WackyRels;
    
use base qw/DBIx::Class::Schema/;


{
  package TestSchema::WackyRels::Grade;
  use base 'DBIx::Class::Core';
    
  __PACKAGE__->table("grade");
  __PACKAGE__->add_columns(
    "letter"    => { data_type => "char", is_nullable => 0, size => 1 },
  );
  __PACKAGE__->set_primary_key("letter");
	
	__PACKAGE__->has_many(
    "things",
    "TestSchema::WackyRels::Thing",
    { "foreign.grade" => "self.letter" },
    { cascade_copy => 0, cascade_delete => 0 },
  );
};


{
  package TestSchema::WackyRels::Size;
  use base 'DBIx::Class::Core';
    
  __PACKAGE__->table("size");
  __PACKAGE__->add_columns(
    "name"    => { data_type => "char", is_nullable => 0, size => 32 },
    "detail"  => { data_type => "varchar", is_nullable => 1, size => 255 },
  );
  __PACKAGE__->set_primary_key("name");

  __PACKAGE__->has_many(
    "parents",
    "TestSchema::WackyRels::Parent",
    { "foreign.size" => "self.name" },
    { cascade_copy => 0, cascade_delete => 0 },
  );
	
	__PACKAGE__->has_many(
    "products",
    "TestSchema::WackyRels::Product",
    { "foreign.size" => "self.name" },
    { cascade_copy => 0, cascade_delete => 0 },
  );
	
	__PACKAGE__->has_many(
    "things",
    "TestSchema::WackyRels::Thing",
    { "foreign.size" => "self.name" },
    { cascade_copy => 0, cascade_delete => 0 },
  );
};

{
  package TestSchema::WackyRels::Parent;
  use base 'DBIx::Class::Core';
    
  __PACKAGE__->table("parent");
  __PACKAGE__->add_columns(
    "id"      => { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "color"   => { data_type => "char", is_nullable => 0, size => 32 },
    "size"    => { data_type => "char", is_nullable => 0, size => 32 },
    "info"    => { data_type => "varchar", is_nullable => 1, size => 255 },
  );
  __PACKAGE__->set_primary_key("id");
  __PACKAGE__->add_unique_constraint("color",["color","size"]);
  
  __PACKAGE__->belongs_to(
    "size",
    "TestSchema::WackyRels::Size",
    { "name" => "size" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
  );

  __PACKAGE__->has_many(
    "children",
    "TestSchema::WackyRels::Child",
    { 
      "foreign.color" => "self.color",
      "foreign.size" => "self.size",
    },
    { cascade_copy => 0, cascade_delete => 0 },
  );
};

{
  package TestSchema::WackyRels::Child;
  use base 'DBIx::Class::Core';
  
  __PACKAGE__->table("child");
  __PACKAGE__->add_columns(
    "id"      => { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "color"   => { data_type => "char", is_nullable => 0, size => 32 },
    "size"    => { data_type => "char", is_nullable => 0, size => 32 },
    "info"    => { data_type => "varchar", is_nullable => 1, size => 255 },
  );
  __PACKAGE__->set_primary_key("id");

  __PACKAGE__->belongs_to(
    "parent",
    "TestSchema::WackyRels::Parent",
    { 
      "color" => "color",
      "size" => "size",
    },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
  );
};


{
  package TestSchema::WackyRels::Product;
  use base 'DBIx::Class::Core';
    
  __PACKAGE__->table("product");
  __PACKAGE__->add_columns(
    "sku"   => { data_type => "char", is_nullable => 0, size => 24 },
    "size"    => { data_type => "char", is_nullable => 0, size => 32 },
    "info"    => { data_type => "varchar", is_nullable => 1, size => 255 },
  );
  __PACKAGE__->set_primary_key("sku");
  
  __PACKAGE__->belongs_to(
    "size",
    "TestSchema::WackyRels::Size",
    { "name" => "size" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
  );

};

{
  package TestSchema::WackyRels::Thing;
  use base 'DBIx::Class::Core';
    
  __PACKAGE__->table("thing");
  __PACKAGE__->add_columns(
    "name"   => { data_type => "char", is_nullable => 0, size => 24 },
    "size"   => { data_type => "char", is_nullable => 1, size => 32 },
    "grade"  => { data_type => "char", is_nullable => 0, size => 1 },
    "info"   => { data_type => "varchar", is_nullable => 1, size => 255 },
  );
  __PACKAGE__->set_primary_key("name");
  
  __PACKAGE__->belongs_to(
    "size",
    "TestSchema::WackyRels::Size",
    { "name" => "size" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "SET NULL" },
  );
  
  __PACKAGE__->belongs_to(
    "grade",
    "TestSchema::WackyRels::Grade",
    { "letter" => "grade" },
    { is_deferrable => 1, on_delete => "RESTRICT", on_update => "CASCADE" },
  );

};

__PACKAGE__->load_classes(qw/Grade Size Parent Child Product Thing/);

1;
